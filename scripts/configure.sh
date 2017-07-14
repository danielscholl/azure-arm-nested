#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Configure the Jumpstart server using Ansible
#  Usage:
#    configure.sh <unique>

#set -euo pipefail
#IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)


###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: provisionShared.sh <unique>" 1>&2; exit 1; }

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


#####################################
## Provision the JumpServer ##
#####################################
HOST=jumpserver
INVENTORY_FILE="config/inventory"

tput setaf 2; echo "'Retrieving IP Address for' ${HOST}..." ; tput sgr0
tput setaf 2; echo 'Creating the ansible inventory files...' ; tput sgr0
cat > config/inventory << EOF1
[jumpserver]
$(az vm list-ip-addresses -g ${UNIQUE} -n ${HOST} --query [].virtualMachine.network.publicIpAddresses[].ipAddress -o tsv)
EOF1


cat > config/.inventory << EOF1
[datatier]
$(az vm list-ip-addresses -g ${UNIQUE}-Data  --query [].virtualMachine.network.privateIpAddresses -otsv)

[apptier]
EOF1

ansible-playbook -i config/inventory ./config/pb.jumpserver.yml
