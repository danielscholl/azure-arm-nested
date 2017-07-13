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

#####################################
## Remove Temporary Resource Group ##
#####################################
CATEGORY=Temp
RESOURCE_GROUP=${UNIQUE}-${CATEGORY}

tput setaf 2; echo "Removing the $RESOURCE_GROUP resource group..." ; tput sgr0
az group delete --name ${RESOURCE_GROUP} --no-wait
