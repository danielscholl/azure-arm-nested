# Run an N-tier application using Linux Systems

This reference architecture shows a solution for running an N-tier application.

The desire was to have the deployment split into multiple resource groups.  The result of this decision then requires
the templates to be orchestrated somewhat by a script which is a bash script using Azure CLI 2.0.

To deploy this solution:

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

7. Execute deploy.sh and pass a required argument to use as a unique prefix (a-z/A-Z/0-9)

```bash
$ deploy.sh <unique>
```

8. To configure the jumpbox server using ansible execute scripts/configure.sh

```bash
$ scripts/configure.sh <unique>
```

9. The deploy script will automatically configure the jump server
## Architecture

