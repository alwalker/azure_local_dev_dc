# Local Development With Azure Resources

## Step 0
In order to perform the following steps you will need to be logged into both Azure as well as the development container registry.  This can be done by the following commands:

    az login
    az account set -s $AZURE_SUB_GUID
    docker login -u myreg myreg.azurecr.io

## Terraform
First create an autovars file using `local.autovars.example` as a template and save it as `local.auto.tfvars` in the same directory. Then run `terraform init` and `terraform apply` to create a resource group in Azure with at least a storage account (with all needed containers) and a Service Bus.  Optionally you can elect to create your SQL Server in Azure as well.  This will also create `docker-compose.yml` and `docker-compose.override.yml` files locally.

## Local Helper Docker Containers
In this repo are two Dockerfiles for creating helper containers:

*  `Dockerfile.mssql-cli` - Containerizes the SQL Server CLI for scripting database manipulation. Tag as `mssql-ci`.
*  `Dockerfile.sqlpackage` - Containerizes the `sqlpackage` command for working with bacpac files. Tag as `sqlpackage`.

You will want to build both of these for later.

## Database Setup
If you have chosen to use a local database container start it and only it first by running `docker-compose up -d database`.  If you want you can also run `docker-compose logs -f` to keep an eye on things. If you are not using a local container to host your database you do not need to include the `--network` option in the folowing commands. Instead change the `--host` option where applicable.  Also, regardless of witch option you choose Terraform will output your connection string when it's done creating everything.

### Fresh Database
If you want to start with a fresh copy of each database with latest migrations run the bellow commands. 

*Note: If using the Azure Database option you do not need to run the CREATE statements.*

    echo "CREATE DATABASE mydb;" | docker run -i --network=local_dev_default --rm mssql-cli -U sa -P '$PASSWORD' -S database

    docker run --rm --network=local_dev_default  myreg.azurecr.io/dbmigrator:latest --database mydb --password '$PASSWORD' --host database

### Import Existing Database
If you want to use an existing database(s) from another environment run the below commands using the image from `Dockerfile.sqlpackage` to export them first.

    docker run -v /tmp/bacs/:/bacs --rm sqlpackage /a:Export /tf:/bacs/mydb.bacpac /scs:"CONNECTION_STRING_TO_EXISTING_DB"

*Note: The folders/volumes being mounted here are arbitrary, use whatever is convenient for you. Or don't use volumes at all and simply `docker cp` the bacpac files out. Also bacpac files can be generated from the Azure console and placed into a blob container of your choosing.*

However you choose to acquire the bacpac files you now need to import them into your database. Again use the image from `Dockerfile.sqlpackage` to do the following.

    docker run -v /tmp/bacs/:/bacs --network=local_dev_default --rm sqlpackage /a:Import /sf:/bacs/mydb.bacpac /tcs:"CONNECTION_STRING_TO_YOUR_DB"

## Docker Compose
Now that your database is set up you can run `docker-compose up` to start the rest of the services.  Once things settle down you should be able to browse to the portal at `http://localhost:9110`.