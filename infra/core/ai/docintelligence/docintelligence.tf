resource "azurerm_cognitive_account" "docIntelligenceAccount" {
  name                          = "doci-${var.resource_name_suffix}"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  kind                          = "FormRecognizer"
  sku_name                      = var.sku["name"]
  custom_subdomain_name         = "doci-${var.resource_name_suffix}"
  public_network_access_enabled = false
  local_auth_enabled            = false
  tags                          = var.tags
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "docintPrivateEndpoint" {
  name                          = "pend-${var.resource_name_suffix}-doci"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "nic-${var.resource_name_suffix}-doci"
  tags                          = var.tags
  private_service_connection {
    name                           = "pend-${var.resource_name_suffix}-doci"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cognitive_account.docIntelligenceAccount.id
    subresource_names               = ["account"]
  }

  private_dns_zone_group {
    name                 = "PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}