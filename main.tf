locals {
  db_conn_str_az    = "Server=tcp:${module.database-server.server_fqdn},1433;Initial Catalog=${module.database.db_name};Persist Security Info=False;User ID=${var.database_login};Password=${var.database_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=3000;"
  db_conn_str_local = "Server=tcp:database,1433;Initial Catalog=DBNAME;Persist Security Info=False;User ID=sa;Password=${var.database_password};MultipleActiveResultSets=False;Encrypt=False;TrustServerCertificate=False;Connection Timeout=3000;"
  blob_conn_str     = "azure.blob://account=${module.storage-account.name};key=${module.storage-account.key}"
}

provider "azurerm" {
  subscription_id = ""
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.base_name}-${var.env}-rg"
  location = var.azure_region
}

module "storage-account" {
  source = "../storage_account"

  azure_region        = var.azure_region
  base_name           = var.base_name
  env                 = var.env
  resource_group_name = azurerm_resource_group.main.name
  tier                = "Standard"
  replication_type    = "LRS"
  unique_token        = var.unique_token
}
module "blob-container" {
  source = "../storage_container"

  container_name        = "blob-container"
  container_access_type = "private"
  storage_account_name  = module.storage-account.name
}

module "database-server" {
  source = "../database_server"

  azure_db            = var.azure_db
  azure_region        = var.azure_region
  base_name           = var.base_name
  env                 = var.env
  resource_group_name = azurerm_resource_group.main.name
  engine_version      = "12.0"
  database_login      = var.database_login
  database_password   = var.database_password
}
module "database-firewall-allow-local" {
  source = "../database_firewall_local_ip"

  resource_group_name = azurerm_resource_group.main.name
  azure_db            = var.azure_db
  env                 = var.env
  server_name         = module.database-server.server_name
}
module "database" {
  source = "../database"

  azure_db            = var.azure_db
  azure_region        = var.azure_region
  base_name           = var.base_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = module.database-server.server_name
}

module "service-bus" {
  source = "../service_bus"

  azure_region        = var.azure_region
  base_name           = var.base_name
  env                 = var.env
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
}

data "template_file" "docker_compose_az_db" {
  template = "${file("docker_compose.tpl")}"

  vars = {
    sb_url                     = module.service-bus.sb_url
    sb_key_name                = "RootManageSharedAccessKey"
    sb_key                     = module.service-bus.sas_key
    blob_connection_string     = local.blob_conn_str
    database_connection_string = local.db_conn_str_az
  }
}

data "template_file" "docker_compose_local_db" {
  template = "${file("docker_compose.tpl")}"

  vars = {
    sb_url                     = module.service-bus.sb_url
    sb_key_name                = "RootManageSharedAccessKey"
    sb_key                     = module.service-bus.sas_key
    blob_connection_string     = local.blob_conn_str
    database_connection_string = local.db_conn_str_local
  }
}

data "template_file" "docker_compose_local_db_override" {
  template = "${file("docker_compose_override.tpl")}"

  vars = {
    db_password = var.database_password
  }
}

resource "local_file" "docker_compose_az" {
  count    = var.azure_db ? 1 : 0
  content  = data.template_file.docker_compose_az_db.rendered
  filename = "docker-compose.yml"
}

resource "local_file" "docker_compose_local" {
  count    = var.azure_db ? 0 : 1
  content  = data.template_file.docker_compose_local_db.rendered
  filename = "docker-compose.yml"
}
resource "local_file" "docker_compose_local_override" {
  count    = var.azure_db ? 0 : 1
  content  = data.template_file.docker_compose_local_db_override.rendered
  filename = "docker-compose.override.yml"
}

output "sb_key_name" {
  value = "RootManageSharedAccessKey"
}
output "sb_url" {
  value = module.service-bus.sb_url
}
output "sb_key" {
  value = module.service-bus.sas_key
}
output "db_connection_string_az" {
  value = local.db_conn_str_az
}
output "db_connection_string_local" {
  value = local.db_conn_str_local
}
output "blob_connection_string" {
  value = local.blob_conn_str
}