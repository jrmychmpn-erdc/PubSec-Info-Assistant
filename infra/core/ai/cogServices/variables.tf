variable "resource_name_suffix" {
  type = string
}

variable "location" {
  type    = string
  default = "" 
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "sku" {
  type = object({
    name = string
  })
  default = {
    name = "S0"
  }
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "key_vault_name" { 
  type = string
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "subnetResourceId" {
  type = string
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}

variable "subnet_id" {
  type    = string
}