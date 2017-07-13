#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Create a App Service Web App
#  Usage:
#    install.sh <unique> <location>

#set -euo pipefail
#IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)


###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: install.sh <unique> <location>" 1>&2; exit 1; }

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi
if [ -f ./.env ]; then source ./.env; fi

if [ ! -z $1 ]; then UNIQUE=$1; fi
if [ ! -z $2 ]; then AZURE_LOCATION=$2; else AZURE_LOCATION=southcentralus; fi
if [ -z $UNIQUE ]; then
  tput setaf 1; echo 'ERROR: UNIQUE not found' ; tput sgr0
  usage;
fi

###############################
## FUNCTIONS                 ##
###############################
function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Global Variable AZURE_LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Global Variable AZURE_LOCATION not set'; tput sgr0
    exit 1;
  fi

  local _result=$(az group show --name $1)
  if [ "$_result"  == "" ]
    then
      az group create --name $1 \
        --location ${AZURE_LOCATION} \
        --query [id,location] -ojsonc
    else
      tput setaf 3;  echo "Resource Group $1 already exists."; tput sgr0
    fi
}
function CreateStorageAccount() {
  # Required Argument $1 = AZURE_RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (AZURE_RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi

  local _storage=$(az group deployment create \
    --resource-group $1 \
    --template-file 'templates/nested/deployStorageAccount.json' \
    --query [properties.outputs.storageAccount.value.name] -otsv)

  echo $_storage
}
function GetStorageConnection() {
  # Required Argument $1 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (STORAGE_ACCOUNT) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az storage account show-connection-string \
    --resource-group $1 \
    --name $2\
    --query connectionString \
    --output tsv)

  echo $_result
}
function CreateBlobContainer() {
  # Required Argument $1 = CONTAINER_NAME
  # Required Argument $2 CONNECTION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (CONTAINER_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (STORAGE_CONNECTION) not received' ; tput sgr0
    exit 1;
  fi

 az storage container create --name $1 \
    --connection-string $2 \
    -ojsonc 1>&2;
}
function GetUrl() {
  # Required Argument $1 = BLOB_NAME
  # Required Argument $2 = TOKEN
  # Required Argument $3 CONTAINER_NAME
  # Required Argument $4 = CONNECTION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (BLOB_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (TOKEN) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (CONTAINER_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $4 ]; then
    tput setaf 1; echo 'ERROR: Argument $4 (CONNECTION) not received' ; tput sgr0
    exit 1;
  fi

  local _url=$(az storage blob url --name $1.json \
    --container-name $3 \
    --connection-string $4 \
    --output tsv)
  echo ${_url}?$2
}
function CreateSASToken() {
  # Required Argument $1 CONTAINER_NAME
  # Required Argument $2 = CONNECTION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (CONTAINER_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (CONNECTION) not received' ; tput sgr0
    exit 1;
  fi

  local _expire=$(date -v+30M -u +%Y-%m-%dT%H:%MZ)
  local _token=$(az storage container generate-sas --name $1 \
  --expiry ${_expire} \
  --permissions r \
  --connection-string $2 \
  --output tsv)
  echo ${_token}
}
function GetParams() {
  # Required Argument $1 = TOKEN

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (TOKEN) not received' ; tput sgr0
    exit 1;
  fi

  local _params="uniquePrefix=${UNIQUE} sasToken=?$1"

  echo ${_params}
}



###############################
## Azure Intialize           ##
###############################
tput setaf 2; echo 'Logging in and setting subscription...' ; tput sgr0

az account set --subscription ${AZURE_SUBSCRIPTION}

if [ ! -d .params ]; then
  tput setaf 1; echo 'WARNING: .params directory initialzed please edit files.' ; tput sgr0
  mkdir .params
  cp templates/*.params.json .params
  exit 1;
fi



##############################
## Temporary Resource Group ##
##############################
CATEGORY=Temp
RESOURCE_GROUP=${UNIQUE}-${CATEGORY}
CONTAINER="templates"

tput setaf 2; echo "Creating the $RESOURCE_GROUP resource group..." ; tput sgr0
CreateResourceGroup ${RESOURCE_GROUP};

tput setaf 2; echo 'Creating a Storage Account...' ; tput sgr0
STORAGE_ACCOUNT=$(CreateStorageAccount ${RESOURCE_GROUP})
echo $STORAGE_ACCOUNT

tput setaf 2; echo 'Getting a Storage Connection...' ; tput sgr0
CONNECTION=$(GetStorageConnection ${RESOURCE_GROUP} ${STORAGE_ACCOUNT})
echo $CONNECTION

tput setaf 2; echo 'Creating a Blob Container...' ; tput sgr0
CreateBlobContainer ${CONTAINER} ${CONNECTION}

tput setaf 2; echo 'Uploading ARM templates to Container...' ; tput sgr0
az storage blob upload-batch \
  --source templates \
  --destination ${CONTAINER} \
  --pattern "*.json" \
  --connection-string ${CONNECTION}

tput setaf 2; echo 'Uploading Custom Scripts to Container...' ; tput sgr0
az storage blob upload-batch \
  --source templates \
  --destination ${CONTAINER} \
  --pattern "support-scripts/**.*" \
  --connection-string ${CONNECTION}

tput setaf 2; echo 'Generating a SAS Token for Container...' ; tput sgr0
TOKEN=$(CreateSASToken ${CONTAINER} ${CONNECTION})
echo $TOKEN



########################################
## Shared Resource Group and Template ##
########################################
CATEGORY=Shared
RESOURCE_GROUP=${UNIQUE}-${CATEGORY}

tput setaf 2; echo "Creating the $RESOURCE_GROUP resource group..." ; tput sgr0
CreateResourceGroup ${RESOURCE_GROUP};

tput setaf 2; echo "Getting the URL for ${CATEGORY} Template..." ; tput sgr0
URL=$(GetUrl deploy${CATEGORY} ${TOKEN} ${CONTAINER} ${CONNECTION})
echo $URL

tput setaf 2; echo "Constructing Parameters for ${CATEGORY} Template..." ; tput sgr0
PARAMS=$(GetParams ${TOKEN})
echo $PARAMS

tput setaf 2; echo "Deploying ${CATEGORY} Template..." ; tput sgr0
az group deployment create \
  --resource-group ${RESOURCE_GROUP} \
  --template-uri ${URL} \
  --parameters @.params/deploy${CATEGORY}.params.json \
  --parameters $(GetParams ${TOKEN}) \
  --query [properties.outputs] -ojsonc



###########################################
## Getting Necessary Parameter Templates ##
###########################################
tput setaf 2; echo 'Getting Parameter...' ; tput sgr0
BACKENDSUBNET=$(az network vnet subnet show --name dataTier \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${UNIQUE}-vnet \
  --query id -otsv)
echo "backendSubnetId=${BACKENDSUBNET}"

tput setaf 2; echo 'Getting Parameter...' ; tput sgr0
KEYVAULT=$(az keyvault show --name ${UNIQUE}-kv \
  --query id -otsv)
echo "keyVaultId=${KEYVAULT}"



#####################################
## App Resource Group and Template ##
#####################################
CATEGORY=App
RESOURCE_GROUP=${UNIQUE}-${CATEGORY}

tput setaf 2; echo "Creating the $RESOURCE_GROUP resource group..." ; tput sgr0
CreateResourceGroup ${RESOURCE_GROUP};

tput setaf 2; echo "Getting the URL for ${CATEGORY} Template..." ; tput sgr0
URL=$(GetUrl deploy${CATEGORY} ${TOKEN} ${CONTAINER} ${CONNECTION})
echo $URL

tput setaf 2; echo "Constructing Parameters for ${CATEGORY} Template..." ; tput sgr0
PARAMS=$(GetParams ${TOKEN})
echo $PARAMS

tput setaf 2; echo "Deploying ${CATEGORY} Template..." ; tput sgr0
az group deployment create \
  --resource-group ${RESOURCE_GROUP} \
  --template-uri ${URL} \
  --parameters @.params/deploy${CATEGORY}.params.json \
  --parameters $(GetParams ${TOKEN}) \
  --parameters keyVaultId=${KEYVAULT} backendSubnetId=${BACKENDSUBNET} \
  --query [properties.outputs] -ojsonc
