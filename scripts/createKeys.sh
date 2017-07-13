#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Create a App Service Web App
#  Usage:
#    createKeys.sh <user>

#set -euo pipefail
#IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: createKeys.sh <user>" 1>&2; exit 1; }

if [ -z $1 ]; then
  tput setaf 1; echo 'ERROR: USER not found' ; tput sgr0
  usage;
fi

mkdir ../.ssh && cd ../.ssh
ssh-keygen -t rsa -b 2048 -C $1 -f id_rsa
