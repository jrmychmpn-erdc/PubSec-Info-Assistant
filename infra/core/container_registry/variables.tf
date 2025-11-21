variable "name" {
  description = "The name"
  type        = string
}

variable "resource_name_suffix" {
  type = string
}

variable "location" {
  description = "Location for all resources."
  type        = string
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type = string
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "private_dns_zone_name" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}