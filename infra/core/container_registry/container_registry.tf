resource "azurerm_container_registry" "acr" {
  name                = var.name
  resource_group_name = var.resourceGroupName
  location            = var.location
  sku                 = "Premium"  // Premium is required for networking features
  admin_enabled       = true       // Enables the admin account for Docker login
  tags                = var.tags
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "ContainerRegistryPrivateEndpoint" {
  name                          = "pend-${var.resource_name_suffix}-cr"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  tags                          = var.tags
  custom_network_interface_name = "nic-${var.resource_name_suffix}-cr"

  private_service_connection {
    name                            = "pend-${var.resource_name_suffix}-cr"
    private_connection_resource_id  = azurerm_container_registry.acr.id
    is_manual_connection            = false
    subresource_names               = ["registry"]
  }

  private_dns_zone_group {
    name                 = "PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}