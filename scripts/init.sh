#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Create a App Service Web App
#  Usage:
#    install.sh <unique>

#set -euo pipefail
#IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)


###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: install.sh <unique>" 1>&2; exit 1; }

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

tput setaf 2; echo "Creating the $RESOURCE_GROUP resource group..." ; tput sgr0
CreateResourceGroup ${RESOURCE_GROUP} ${AZURE_LOCATION};
az group show --name ${RESOURCE_GROUP} -ojsonc

tput setaf 2; echo 'Deploying Storage Account Template...' ; tput sgr0
STORAGE_ACCOUNT=$(CreateStorageAccount ${RESOURCE_GROUP})
echo $STORAGE_ACCOUNT

tput setaf 2; echo "Retrieving Connection for Storage Account ${STORAGE_ACCOUNT}..." ; tput sgr0
CONNECTION=$(GetStorageConnection ${RESOURCE_GROUP} ${STORAGE_ACCOUNT})
echo $CONNECTION

tput setaf 2; echo "Creating Template Container in Storage Account ${STORAGE_ACCOUNT}..." ; tput sgr0
CreateBlobContainer ${AZURE_STORAGE_CONTAINER} ${CONNECTION}

tput setaf 2; echo 'Uploading ARM templates to Container...' ; tput sgr0
az storage blob upload-batch \
  --source templates \
  --destination ${AZURE_STORAGE_CONTAINER} \
  --pattern "*.json" \
  --connection-string ${CONNECTION}

tput setaf 2; echo 'Uploading Custom Scripts to Container...' ; tput sgr0
az storage blob upload-batch \
  --source templates \
  --destination ${AZURE_STORAGE_CONTAINER} \
  --pattern "support-scripts/**.*" \
  --connection-string ${CONNECTION}

tput setaf 2; echo 'Generating a SAS Token for Template Container...' ; tput sgr0
TOKEN=$(CreateSASToken ${AZURE_STORAGE_CONTAINER} ${CONNECTION})
echo $TOKEN
