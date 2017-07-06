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

usage() { echo "Usage: install.sh <unique> <location>" 1>&2; exit 1; }

###############################
## SCRIPT SETUP              ##
###############################

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi
if [ -f ./.env ]; then source ./.env; fi

if [ ! -z $1 ]; then UNIQUE=$1; fi
if [ ! -z $2 ]; then AZURE_LOCATION=$2; else AZURE_LOCATION=southcentralus; fi
if [ -z $UNIQUE ]; then
  tput setaf 1; echo 'ERROR: UNIQUE not found' ; tput sgr0
  usage;
fi


###############################
## Azure Intialize           ##
###############################
tput setaf 2; echo 'Logging in and setting subscription...' ; tput sgr0

#az login
az account set \
  --subscription ${AZURE_SUBSCRIPTION}


###############################
## Manage Resource Group ##
###############################
tput setaf 2; echo 'Creating the manage resource group...' ; tput sgr0

AZURE_RESOURCE_GROUP=${UNIQUE}-manage
RESULT=$(az group show --name ${AZURE_RESOURCE_GROUP})
if [ "$RESULT"  == "" ]
	then
		az group create \
      --location ${AZURE_LOCATION} \
      --name ${AZURE_RESOURCE_GROUP}
	else
		echo "Resource Group ${AZURE_RESOURCE_GROUP} already exists."
	fi


tput setaf 2; echo 'Deploying the automation template...' ; tput sgr0

AZURE_STORAGE_ACCOUNT=$(az group deployment create --name Automation \
  --resource-group ${AZURE_RESOURCE_GROUP} \
  --template-file 'azuredeploy.json' \
  --query [properties.outputs.storageAccountName.value] -otsv)

CONNECTION=$(az storage account show-connection-string \
  --resource-group ${AZURE_RESOURCE_GROUP} \
  --name ${AZURE_STORAGE_ACCOUNT} \
  --query connectionString \
  --output tsv)

AZURE_STORAGE_CONTAINER="templates"
az storage container create --name ${AZURE_STORAGE_CONTAINER} \
  --connection-string ${CONNECTION}


tput setaf 2; echo 'Uploading ARM templates to storage...' ; tput sgr0

az storage blob upload-batch \
  --source templates \
  --destination ${AZURE_STORAGE_CONTAINER} \
  --pattern "*.json" \
  --connection-string ${CONNECTION}


###############################
## Automation Resource Group ##
###############################
tput setaf 2; echo 'Creating the shared resource group...' ; tput sgr0

CATEGORY=shared
AZURE_RESOURCE_GROUP=${UNIQUE}-${CATEGORY}
RESULT=$(az group show --name ${AZURE_RESOURCE_GROUP})
if [ "$RESULT"  == "" ]
	then
		az group create \
      --location ${AZURE_LOCATION} \
      --name ${AZURE_RESOURCE_GROUP}
	else
		echo "Resource Group ${AZURE_RESOURCE_GROUP} already exists."
	fi

###############################
## Deploy ARM Template       ##
###############################
tput setaf 2; echo 'Deploying Parent Template...' ; tput sgr0

EXPIRE_TIME=$(date -v+30M -u +%Y-%m-%dT%H:%MZ)
TOKEN=$(az storage container generate-sas --name templates \
  --expiry ${EXPIRE_TIME} \
  --permissions r \
  --connection-string ${CONNECTION} \
  --output tsv)

URL=$(az storage blob url --name deploy${CATEGORY}.json \
  --container-name ${AZURE_STORAGE_CONTAINER} \
  --connection-string ${CONNECTION} \
  --output tsv)

az group deployment create \
  --resource-group ${AZURE_RESOURCE_GROUP} \
  --template-uri ${URL}?${TOKEN} \
  --parameters @deploy${CATEGORY}.params.json \
  --parameters uniquePrefix=${UNIQUE} sasToken="?${TOKEN}" \
  --query [properties.outputs] --output jsonc
