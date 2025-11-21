resource "azurerm_cognitive_account" "openaiAccount" {
  count                               = var.useExistingAOAIService ? 0 : 1
  name                                = "oai-${var.resource_name_suffix}"
  location                            = var.location
  resource_group_name                 = var.resourceGroupName
  kind                                = var.kind
  sku_name                            = var.sku["name"]
  public_network_access_enabled       = false
  local_auth_enabled                  = false
  outbound_network_access_restricted  = var.outbound_network_access_restricted
  custom_subdomain_name               = "oai-${var.resource_name_suffix}"
  tags = var.tags

  network_acls {
    default_action = "Allow"
    ip_rules       = var.network_acls_ip_rules

    dynamic "virtual_network_rules" {
      for_each = [1]
      content {
        subnet_id = var.subnet_id
      }
    }
  }
}

resource "azurerm_cognitive_deployment" "deployment" {
  count                 = var.useExistingAOAIService ? 0 : length(var.deployments)
  name                  = var.deployments[count.index].name
  cognitive_account_id  = azurerm_cognitive_account.openaiAccount[0].id
  rai_policy_name       = var.deployments[count.index].rai_policy_name
  model {
    format              = "OpenAI"
    name                = var.deployments[count.index].model.name
    version             = var.deployments[count.index].model.version
  }
  sku {
    name                = var.deployments[count.index].sku.name
    capacity            = var.deployments[count.index].sku.capacity
  }
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs" {
  count                      = var.useExistingAOAIService ? 0 : 1
  name                       = azurerm_cognitive_account.openaiAccount[0].name
  target_resource_id         = azurerm_cognitive_account.openaiAccount[0].id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId
  enabled_log  {
    category = "Audit"
  }
  enabled_log {
    category = "RequestResponse"
  }
  enabled_log {
    category = "Trace"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_private_endpoint" "openaiPrivateEndpoint" {
  count                         = var.useExistingAOAIService ? 0 : 1
  name                          = "pend-${var.resource_name_suffix}-oai"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "nic-${var.resource_name_suffix}-oai"
  tags                          = var.tags
  private_service_connection {
    name                            = "pend-${var.resource_name_suffix}-oai"
    is_manual_connection            = false
    private_connection_resource_id  = azurerm_cognitive_account.openaiAccount[count.index].id
    subresource_names               = ["account"]
  }

  private_dns_zone_group {
    name                 = "PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids

  }
}