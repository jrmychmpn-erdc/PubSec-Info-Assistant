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

resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = var.logAnalyticsName
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku                 = var.skuName
  tags                = var.tags
  retention_in_days   = 30
}

resource "azurerm_application_insights" "applicationInsights" {
  name                = var.applicationInsightsName
  location            = var.location
  resource_group_name = var.resourceGroupName
  application_type    = "web"
  tags                = var.tags
  workspace_id        = azurerm_log_analytics_workspace.logAnalytics.id
}

// Create Diagnostic Setting for NSG here since the log analytics workspace is created here after the network is created
resource "azurerm_monitor_diagnostic_setting" "nsg_diagnostic_logs" {
  count                      = var.is_secure_mode ? 1 : 0
  name                       = var.nsg_name
  target_resource_id         = var.nsg_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logAnalytics.id
  enabled_log  {
    category = "NetworkSecurityGroupEvent"
  }
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

// Create Azure Private Link Scope for Azure Monitor
resource "azurerm_monitor_private_link_scope" "ampls" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "${var.privateLinkScopeName}-pls"
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

// add scoped resource for Log Analytics Workspace
resource "azurerm_monitor_private_link_scoped_service" "ampl-ss_log_analytics" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "${var.privateLinkScopeName}-law-connection"
  resource_group_name = var.resourceGroupName
  scope_name          = azurerm_monitor_private_link_scope.ampls[0].name
  linked_resource_id  = azurerm_log_analytics_workspace.logAnalytics.id
}

// add scope resoruce for app insights
resource "azurerm_monitor_private_link_scoped_service" "ampl_ss_app_insights" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "${var.privateLinkScopeName}-appInsights-connection"
  resource_group_name = var.resourceGroupName
  scope_name          = azurerm_monitor_private_link_scope.ampls[0].name
  linked_resource_id  = azurerm_application_insights.applicationInsights.id
}

data "azurerm_subnet" "subnet" {
  count                = var.is_secure_mode ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

// add private endpoint for azure monitor - metrics, app insights, log analytics
resource "azurerm_private_endpoint" "ampls" {
  count                             = var.is_secure_mode ? 1 : 0
  name                              = "${var.privateLinkScopeName}-private-endpoint"
  location                          = var.location
  resource_group_name               = var.resourceGroupName
  subnet_id                         = data.azurerm_subnet.subnet[0].id
  custom_network_interface_name     = "infoasstamplsnic"
  tags                              = var.tags
  private_service_connection {
    name                            = "${var.privateLinkScopeName}-privateserviceconnection"
    private_connection_resource_id  = azurerm_monitor_private_link_scope.ampls[0].id
    is_manual_connection            = false
    subresource_names               = [var.groupId]
  }

  private_dns_zone_group {
    name                            = "ampls"
    private_dns_zone_ids = [
        data.azurerm_private_dns_zone.monitor.id,
        data.azurerm_private_dns_zone.oms.id,
        data.azurerm_private_dns_zone.ods.id,
        data.azurerm_private_dns_zone.agentsvc.id,
        var.privateDnsZoneResourceIdBlob
    ]
  }

  depends_on = [
    azurerm_monitor_private_link_scope.ampls,
    azurerm_monitor_private_link_scoped_service.ampl-ss_log_analytics,
    azurerm_monitor_private_link_scoped_service.ampl_ss_app_insights,
    data.azurerm_private_dns_zone.monitor,
    data.azurerm_private_dns_zone.oms,
    data.azurerm_private_dns_zone.ods,
    data.azurerm_private_dns_zone.agentsvc
  ]
}

# resource "azurerm_private_dns_zone" "monitor" {
#   count               = var.is_secure_mode ? 1 : 0
#   name                = var.privateDnsZoneNameMonitor
#   resource_group_name = var.resourceGroupName
#   tags                = var.tags
# }

data "azurerm_private_dns_zone" "monitor" {
  provider            = azurerm.infra_internal
  name                = var.privateDnsZoneNameMonitor
  resource_group_name = local.private_dns_zone_resource_group
}

resource "azurerm_private_dns_a_record" "monitor_api" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "api"
  zone_name           = data.azurerm_private_dns_zone.monitor.name
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 7)]
}

resource "azurerm_private_dns_a_record" "monitor_global" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "global.in.ai"
  zone_name           = data.azurerm_private_dns_zone.monitor.name
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 8)]
}

resource "azurerm_private_dns_a_record" "monitor_profiler" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "profiler"
  zone_name           = data.azurerm_private_dns_zone.monitor.name
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 9)]
}

resource "azurerm_private_dns_a_record" "monitor_live" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "live"
  zone_name           = data.azurerm_private_dns_zone.monitor.name
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 10)]
}

resource "azurerm_private_dns_a_record" "monitor_snapshot" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "snapshot"
  zone_name           = data.azurerm_private_dns_zone.monitor.name
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 11)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitor-net" {
  provider              = azurerm.infra_internal
  count                 = var.is_secure_mode ? 1 : 0
  name                  = "infoasst-pl-monitor-net"
  resource_group_name   = local.private_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.monitor.name
  virtual_network_id    = var.vnet_id
}

# resource "azurerm_private_dns_zone" "oms" {
#   count               = var.is_secure_mode ? 1 : 0
#   name                = var.privateDnsZoneNameOms
#   resource_group_name = var.resourceGroupName
#   tags                = var.tags
# }

data "azurerm_private_dns_zone" "oms" {
  provider            = azurerm.infra_internal
  name                = var.privateDnsZoneNameOms
  resource_group_name = local.private_dns_zone_resource_group
}

resource "azurerm_private_dns_a_record" "oms_law_id" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "infoasst-pl-oms-law-id"
  zone_name           = data.azurerm_private_dns_zone.oms.name
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 4)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "oms-net" {
  provider              = azurerm.infra_internal
  count                 = var.is_secure_mode ? 1 : 0
  name                  = "infoasst-pl-oms-net"
  resource_group_name   = local.private_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.oms.name
  virtual_network_id    = var.vnet_id
}

# resource "azurerm_private_dns_zone" "ods" {
#   count               = var.is_secure_mode ? 1 : 0
#   name                = var.privateDnSZoneNameOds
#   resource_group_name = var.resourceGroupName
#   tags                = var.tags
# }

data "azurerm_private_dns_zone" "ods" {
  provider            = azurerm.infra_internal
  name                = var.privateDnSZoneNameOds
  resource_group_name = local.private_dns_zone_resource_group
}

resource "azurerm_private_dns_a_record" "ods_law_id" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "infoasst_pl_ods_law_id"
  zone_name           = data.azurerm_private_dns_zone.ods.name
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 5)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods-net" {
  provider              = azurerm.infra_internal
  count                 = var.is_secure_mode ? 1 : 0
  name                  = "infoasst-pl-ods-net"
  resource_group_name   = local.private_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.ods.name
  virtual_network_id    = var.vnet_id
}

# resource "azurerm_private_dns_zone" "agentsvc" {
#   count               = var.is_secure_mode ? 1 : 0
#   name                = var.privateDnsZoneNameAutomation
#   resource_group_name = var.resourceGroupName
#   tags                = var.tags
# }

data "azurerm_private_dns_zone" "agentsvc" {
  provider            = azurerm.infra_internal
  name                = var.privateDnsZoneNameAutomation
  resource_group_name = local.private_dns_zone_resource_group
}

resource "azurerm_private_dns_a_record" "agentsvc_law_id" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "infoasst_pl_agentsvc_law_id"
  zone_name           = data.azurerm_private_dns_zone.agentsvc.name
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 6)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc-net" {
  provider              = azurerm.infra_internal
  count                 = var.is_secure_mode ? 1 : 0
  name                  = "infoasst-pl-agentsvc-net"
  resource_group_name   = local.private_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.agentsvc.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_a_record" "blob_scadvisorcontentpld" {
  provider            = azurerm.infra_internal
  count               = var.is_secure_mode ? 1 : 0
  name                = "scadvisorcontentpl"
  zone_name           = var.privateDnsZoneNameBlob
  resource_group_name = local.private_dns_zone_resource_group
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 12)]
}