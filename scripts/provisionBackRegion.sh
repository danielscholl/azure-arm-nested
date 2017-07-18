#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Create the Common Resource Group and Deploy the Common Template
#  Usage:
#    provisionBack.sh <unique>

#set -euo pipefail
#IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)


###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: provisionBack.sh <unique>" 1>&2; exit 1; }

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi
if [ -f ./.env ]; then source ./.env; fi
if [ -f ./scripts/functions.sh ]; then source ./scripts/functions.sh; fi

if [ ! -z $1 ]; then UNIQUE=$1; fi
if [ -z $UNIQUE ]; then
  tput setaf 1; echo 'ERROR: UNIQUE not found' ; tput sgr0
  usage;
fi
if [ -z ${AZURE_LOCATION} ]; then
  tput setaf 1; echo 'ERROR: Global Variable AZURE_LOCATION not set'; tput sgr0
  exit 1;
fi
if [ -z ${AZURE_STORAGE_CONTAINER} ]; then
  tput setaf 1; echo 'ERROR: Global Variable AZURE_STORAGE_CONTAINER not set'; tput sgr0
  exit 1;
fi


###############################
## Azure Intialize           ##
###############################
tput setaf 2; echo 'Logging in and setting subscription...' ; tput sgr0

az account set --subscription ${AZURE_SUBSCRIPTION}


########################################
## Retrieving Parameter Information  ##
########################################
CATEGORY=Temp
RESOURCE_GROUP=${UNIQUE}-${CATEGORY}

tput setaf 2; echo "Retrieving Storage Account in ${RESOURCE_GROUP}..." ; tput sgr0
STORAGE_ACCOUNT=$(GetStorageAccount ${RESOURCE_GROUP});
echo ${STORAGE_ACCOUNT}

tput setaf 2; echo "Retrieving Connection for Storage Account ${STORAGE_ACCOUNT}..." ; tput sgr0
CONNECTION=$(GetStorageConnection ${RESOURCE_GROUP} ${STORAGE_ACCOUNT})
echo $CONNECTION

tput setaf 2; echo "Retrieving Key for Storage Account ${STORAGE_ACCOUNT}..." ; tput sgr0
STORAGEKEY=$(az storage account keys list --account-name ${STORAGE_ACCOUNT} \
  --resource-group ${RESOURCE_GROUP} \
  --query '[0].value' \
  --output tsv)

tput setaf 2; echo 'Generating a SAS Token for Container...' ; tput sgr0
TOKEN=$(CreateSASToken ${AZURE_STORAGE_CONTAINER} ${CONNECTION})
echo $TOKEN



#################################
## Resource Group and Template ##
#################################
CATEGORY=Back
RESOURCE_GROUP=${UNIQUE}-${CATEGORY}

tput setaf 2; echo "Creating the $RESOURCE_GROUP resource group..." ; tput sgr0
CreateResourceGroup ${RESOURCE_GROUP} ${AZURE_LOCATION};

# Deploy Back
TEMPLATE='deployBack'
tput setaf 2; echo "Getting the URL for ${TEMPLATE}..." ; tput sgr0
URL=$(GetUrl ${TEMPLATE} ${TOKEN} ${AZURE_STORAGE_CONTAINER} ${CONNECTION})
echo $URL

tput setaf 2; echo 'Getting Required Parameters...' ; tput sgr0
SUBNETID=$(az network vnet subnet show --name back \
  --resource-group ${UNIQUE} \
  --vnet-name ${UNIQUE}-vnet \
  --query id -otsv)
KEYVAULT=$(az keyvault show --name ${UNIQUE}-kv \
  --query id -otsv)


tput setaf 2; echo "Deploying ${CATEGORY} Template..." ; tput sgr0
az group deployment create \
  --resource-group ${RESOURCE_GROUP} \
  --template-uri ${URL} \
  --parameters @.params/deploy${CATEGORY}.params.json \
  --parameters uniquePrefix=${UNIQUE} sasToken=?$TOKEN \
  --parameters keyVaultId=${KEYVAULT} subnetId=${SUBNETID} \
  --parameters storageAccount=${STORAGE_ACCOUNT} storageKey=${STORAGEKEY} \
  --query [properties.outputs] -ojsonc


