locals {
  consistencyPolicy = {
    Eventual = {
      defaultConsistencyLevel = "Eventual"
    }
    ConsistentPrefix = {
      defaultConsistencyLevel = "ConsistentPrefix"
    }
    Session = {
      defaultConsistencyLevel = "Session"
    }
    BoundedStaleness = {
      defaultConsistencyLevel = "BoundedStaleness"
      maxStalenessPrefix      = var.maxStalenessPrefix
      maxIntervalInSeconds    = var.maxIntervalInSeconds
    }
    Strong = {
      defaultConsistencyLevel = "Strong"
    }
  }
  locations = [
    {
      locationName     = var.location
      failoverPriority = 0
      isZoneRedundant  = false
    }
  ]
}

resource "azurerm_cosmosdb_account" "cosmosdb_account" {
  name                          = "cosmos-${var.resource_name_suffix}"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  tags                          = var.tags
  public_network_access_enabled = false
  local_authentication_disabled = true

  consistency_policy {
    consistency_level       = var.defaultConsistencyLevel
    max_interval_in_seconds = var.maxIntervalInSeconds
    max_staleness_prefix    = var.maxStalenessPrefix
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }
}

resource "azurerm_cosmosdb_sql_database" "log_database" {
  name                = var.logDatabaseName
  resource_group_name = var.resourceGroupName
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
}

resource "azurerm_cosmosdb_sql_container" "log_container" {
  name                = var.logContainerName
  resource_group_name = var.resourceGroupName
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
  database_name       = azurerm_cosmosdb_sql_database.log_database.name

  partition_key_paths = ["/file_name"]
}

resource "azurerm_private_endpoint" "cosmosPrivateEndpoint" {
  name                          = "pend-${var.resource_name_suffix}-cosmos"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "nic-${var.resource_name_suffix}-cosmos"
  tags                          = var.tags
  private_service_connection {
    name                           = "pend-${var.resource_name_suffix}-cosmos"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmosdb_account.id
    is_manual_connection           = false
    subresource_names              = ["SQL"]
    
  }
  private_dns_zone_group {
    name                 = "PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}