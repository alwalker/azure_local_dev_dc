variable "azure_region" {
  type    = string
  default = "Central US"
}

variable "base_name" {
  type    = string
  default = ""
}

variable "env" {
  type = string
}

variable "azure_db" {
  type    = bool
  default = true
}

variable "unique_token" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "sendgrid_api_key" {
  type = string
}

variable "switch_password" {
  type = string
}

variable "storage_presigned_key" {
  type = string
}

variable "database_login" {
  type = string
}

variable "database_password" {
  type = string
}

variable "iron_pdf_lic" {
  type = string
}

variable "product_catalog_api_key" {
  type = string
}

variable "client_account_api_db" {
  type = string
}

variable "product_catalog_db" {
  type = string
}