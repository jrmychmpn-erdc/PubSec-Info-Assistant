terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.3.0"
      configuration_aliases = [azurerm.infra_internal]
    }
  }
}

locals {
  private_dns_zone_resource_group = "Network"
}

data "azurerm_private_dns_zone" "pr_dns_zone" {
  provider            = azurerm.infra_internal
  name                = var.name
  resource_group_name = local.private_dns_zone_resource_group
}

# resource "azurerm_private_dns_zone" "pr_dns_zone" {
#   name                = var.name
#   resource_group_name = var.resourceGroupName
#   tags                = var.tags
# }

resource "azurerm_private_dns_zone_virtual_network_link" "pr_dns_vnet_link" {
  provider              = azurerm.infra_internal
  name                  = var.vnetLinkName
  resource_group_name   = local.private_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.pr_dns_zone.name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
}
