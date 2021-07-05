version: '3'
services:
  worker:
    image: myreg.azurecr.io/worker:latest
    ports:
      - "9100:80"
    environment:
      AzServiceBusConnection__HostUrl: "${sb_url}"
      AzServiceBusConnection__SAS__KeyName: "${sb_key_name}"
      AzServiceBusConnection__SAS__SharedAccessKey: "${sb_key}"
      ConnectionStrings__DB: "${database_connection_string}"
      ConnectionStrings__BlobStorage: "${blob_connection_string}"
  api:
    image: myreg.azurecr.io/api:latest
    ports:
      - "9109:3000"
    environment:
      AzServiceBusConnection__HostUrl: "${sb_url}"
      AzServiceBusConnection__SAS__KeyName: "${sb_key_name}"
      AzServiceBusConnection__SAS__SharedAccessKey: "${sb_key}"
      ConnectionStrings__DB: "${database_connection_string}"
      ConnectionStrings__BlobStorage: "${blob_connection_string}"
  portal:
    image: myreg.azurecr.io/portal:latest
    links:
      - "api"
    ports:
      - "9110:80"
    environment:
      NGINX_ENV: local