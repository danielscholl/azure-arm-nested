# Run an N-tier application using Linux Systems

This reference architecture shows a custom built solution for running a Linux N-tier application.

- Network -- 4 Subnets (dmz, front, back, manage) protected by Network Security Groups
- Storage -- A single Storage Account for Machine Diagnostics
- Load Balanced Linux Pool -- A configurable amount of Linux Servers with a load balancer in the Backend.
- Application Gateway Routed Linux Scale Set -- A configurable instance of a Linux Scale Set with Traffic Routing in the Front End
- Container Service in the Font End (Coming)
- JumpStart Server -- An ansible management machine used to configure and manage the linux servers
- Key Vault -- Holds SSH keys used to configure Linux Servers
- OMS -- Operations Management used to monitor and manage infrastructure.

Single Region Deployment:  All resources deployed using a single region.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdanielscholl%2Fazure-arm-nested%2Fmaster%2FdeployAzure.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fdanielscholl%2Fazure-arm-nested%2Fmaster%2FdeployAzure.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>


Multiple Region Deployment:

To meet a requirement to isolate resources into multiple resource groups the solution also includes a scripted solution
which allows RBAC rules to be then applied and access controlled.

- Region 1 -- Virtual Network, Jumpserver, Diagnostic Storage.  
- Region 2 -- Backend Servers and Load Balancer.  
- Region 3 -- Frontend Servers and App Gateway.  
- Region 4 -- OMS Workspace.  

The chosen solution to make this happen was to create control bash scripts using CLI 2.0 to gather parameters and deploy templates.

An additional requirement exists to deploy templates from a Private Storage Blob so that the designed solution could be
used without tapping into a public github repository.


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


6. Create an SSH Key to use as necessary.

```bash
$ mkdir .ssh && cd .ssh
$ ssh-keygen -t rsa -b 4096 -C "azureuser@email.com" -f id_rsa
```


7. Initialize a Temporary Resource Group to hold a Storage Account for hosting private templates and upload all of them. 

```bash
$ scripts/init.sh <unique>
```


8. Provision the Resources for the Default Region.

```bash
$ scripts/provisionDefaultRegion.sh <unique>
```


9. Provision the Resources for the Backend Region.

```bash
$ scripts/provisionBackRegion.sh <unique>
```


10. Provision the Resources for the Front Region.

```bash
$ scripts/provisionFrontRegion.sh <unique>
```


11. Provision the Resources for the Monitor Region.

```bash
$ scripts/provisionMonitor.sh <unique>
```


12. Using Ansible configure the JumpStart Server to be an ansible control server.

```bash
$ scripts/configure.sh <unique>
```
>Note: Requires Ansible to be installed locally


13. Connect to the JumpStart Server via ssh

```bash
$ scripts/connect.sh <unique>
```

14. Cleanup the Temporary Resource Group

```bash
$ scripts/clean.sh <unique>
```

## Architecture

![[0]][0]

[0]: ./media/Architecture.png "Architecture Diagram"



## TODO List

1. Add a Custom Extension Script configuring an Azure Storage Driver (Flocker/REX-Ray)
2. Build Ansible Scripts to create a Cassandra Cluster in the Backend
3. Build Ansible Scripts to create a RabbitMQ Cluster in the Backend
4. Add Deployment Templates to configure CosmosDB, RedisCache in the Backend
5. Add Deployment Templates to configure a MESOS Cluster in the Frontend (option ScaleSets/ ACS)
