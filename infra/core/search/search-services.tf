
resource "azurerm_search_service" "search" {
  name                          = "srch-${var.resource_name_suffix}"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  sku                           = var.sku["name"]
  tags                          = var.tags
  public_network_access_enabled = false
  local_authentication_enabled  = false
  replica_count                 = 1
  partition_count               = 1
  semantic_search_sku           = var.semanticSearch 

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "searchPrivateEndpoint" {
  name                          = "pend-${var.resource_name_suffix}-srch"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "nic-${var.resource_name_suffix}-srch"
  tags                          = var.tags
  private_service_connection {
    name                           = "pend-${var.resource_name_suffix}-srch"
    private_connection_resource_id = azurerm_search_service.search.id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}