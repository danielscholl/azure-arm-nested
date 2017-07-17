# Run an N-tier application using Linux Systems

This reference architecture shows a solution for running an N-tier application.

Single Region Deployment:  All resources deployed into a single region.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdanielscholl%2Fazure-arm-nested%2Fmaster%2Ftemplates%2FdeployAzure.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fdanielscholl%2Fazure-arm-nested%2Fmaster%2Ftemplates%2FdeployAzure.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>


Multiple Region Deployment:

In order to RBAC protect certain items the desire was to split the deployment into multiple regions. Region 1 -- Virtual Network, Jumpserver, Diagnostic Storage.  Region 2 -- Backend Servers and Load Balancer.  Region 3 -- Frontend Servers and App Gateway.  Region 4 -- OMS Workspace.  

The best solution to make this happen was to create bash scripts using CLI 2.0 and templates together.


1. Clone the Solution

```bash
$ git clone https://github.com/danielscholl/azure-arm-nested.git
```

2. Login to Azure with the CLI.  (az login)

```bash
$ az login
```

3. Copy the .env_sample to .env and set required global environment variables

>NOTE: To get subscription id for an account.  az account show --query id -otsv


4. Create a private .params directory and copy the params file to it.

```bash
$ mkdir .params
$ cp templates/*.params.json .params
```

5. Edit the params file and add required values

>NOTE: To get object id of a user.  az ad user show --upn <your_login_name>


6. Create an SSH Key to use if necessary.

```bash
$ mkdir .ssh && cd .ssh
$ ssh-keygen -t rsa -b 4096 -C "azureuser@email.com" -f id_rsa
```

7. Initialize a Temporary Resource Group to hold a Storage Account for hosting private templates. 

```bash
$ scripts/init.sh <unique>
```

8. Provision the Shared Resources of a network, key-vault and jumpserver

```bash
$ scripts/provision.sh <unique>
```

9. Provision the Backend Resources including (n)Virtual Machines in an availability set and a Load Balancer

```bash
$ scripts/provisionBack.sh <unique>
```

10. Provision the Monitor Resource including a OMS WorkSpace with 5 Solutions

```bash
$ scripts/provisionMonitor.sh <unique>
```

11. Configure the JumpStart Server with Ansible to manage Systems using localhost Ansible

```bash
$ scripts/configure.sh <unique>
```

12. Connect to the JumpStart Server via ssh

```bash
$ scripts/connect.sh <unique>
```

13. Cleanup the Temporary Resource Group

```bash
$ scripts/cleanup.sh <unique>
```

## Architecture

![[0]][0]

[0]: ./media/Architecture.png "Architecture Diagram"


