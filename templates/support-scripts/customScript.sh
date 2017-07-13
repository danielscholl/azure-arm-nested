#!/bin/sh
# Copyright (c) 2017, cloudcodeit.com
## This Script will install
# - Support for SMB 3.0 File Share Mounts
# - Ansible
# - Ansible Azure Module Support

# Register the Azure Package Area
sudo echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893

# Update and Install Packages
sudo apt-get -y update
sudo apt-get -y install apt-transport-https libssl-dev libffi-dev python-dev build-essential python-pip ansible cifs-utils azure-cli

# Install required Python Modules
sudo pip install --upgrade pip
sudo pip install azure==2.0.0rc5 msrestazure dnspython

echo "Custom Script Extension Completed -- $(date -R)!"
