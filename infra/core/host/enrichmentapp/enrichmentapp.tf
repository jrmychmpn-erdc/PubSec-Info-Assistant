resource "azurerm_service_plan" "appServicePlan" {
  name                          = "plan-${var.resource_name_suffix}-enrichment"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  sku_name                      = var.sku["size"]
  worker_count                  = var.sku["capacity"]
  os_type                       = "Linux"
  tags                          = var.tags
  per_site_scaling_enabled      = false
  zone_balancing_enabled        = false
}

resource "azurerm_monitor_autoscale_setting" "scaleout" {
  name                = azurerm_service_plan.appServicePlan.name
  resource_group_name = var.resourceGroupName
  location            = var.location
  target_resource_id  = azurerm_service_plan.appServicePlan.id
  tags                = var.tags
  profile {
    name = "Scale out condition"
    capacity {
      default = 1
      minimum = 1
      maximum = 5
    }

    rule {
      metric_trigger {
        metric_name         = "CpuPercentage"
        metric_resource_id  = azurerm_service_plan.appServicePlan.id
        time_grain          = "PT1M"
        statistic           = "Average"
        time_window         = "PT5M"
        time_aggregation    = "Average"
        operator            = "GreaterThan"
        threshold           = 60
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name         = "CpuPercentage"
        metric_resource_id  = azurerm_service_plan.appServicePlan.id
        time_grain          = "PT1M"
        statistic           = "Average"
        time_window         = "PT10M"
        time_aggregation    = "Average"
        operator            = "LessThan"
        threshold           = 20
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT15M"
      }
    }
  }
}

resource "azurerm_linux_web_app" "enrichmentapp" {
  name                                            = "app-${var.resource_name_suffix}-enrichment"
  location                                        = var.location
  resource_group_name                             = var.resourceGroupName
  service_plan_id                                 = azurerm_service_plan.appServicePlan.id
  https_only                                      = true
  tags                                            = var.tags
  webdeploy_publish_basic_authentication_enabled  = false
  client_affinity_enabled                         = false
  enabled                                         = true
  public_network_access_enabled                   = false
  virtual_network_subnet_id                       = var.subnetIntegration_id
  site_config {
    always_on                                     = var.alwaysOn
    app_command_line                              = var.appCommandLine
    ftps_state                                    = var.ftpsState
    health_check_path                             = var.healthCheckPath
    health_check_eviction_time_in_min             = 10
    http2_enabled                                 = true
    use_32_bit_worker                             = false
    worker_count                                  = 1
    container_registry_use_managed_identity       = true

    application_stack {
      docker_image_name         = "${var.container_registry}/enrichmentapp:latest"
      docker_registry_url       = "https://${var.container_registry}"
      docker_registry_username  = var.container_registry_admin_username
      docker_registry_password  = var.container_registry_admin_password
    }
  }

  app_settings = merge(
    var.appSettings,
    {
      "SCM_DO_BUILD_DURING_DEPLOYMENT"            = lower(tostring(var.scmDoBuildDuringDeployment))
      "ENABLE_ORYX_BUILD"                         = tostring(var.enableOryxBuild)
      "APPLICATIONINSIGHTS_CONNECTION_STRING"     = var.applicationInsightsConnectionString
      "KEY_EXPIRATION_DATE"                       = timeadd(timestamp(), "4320h") # Added expiration date setting for keys
      "WEBSITE_PULL_IMAGE_OVER_VNET"              = "true"
      "WEBSITES_PORT"                             = "6000"
      "WEBSITES_CONTAINER_START_TIME_LIMIT"       = "1600"
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE"       = "false"
    }
  )

  identity {
    type = var.managedIdentity ? "SystemAssigned" : null
  }

  logs {
    application_logs {
      file_system_level = "Verbose"
    }
    http_logs {
      file_system {
        retention_in_days = 1
        retention_in_mb   = 35
      }
    }
    failed_request_tracing = true
  }

}

resource "azurerm_role_assignment" "acr_pull_role" {
  principal_id         = azurerm_linux_web_app.enrichmentapp.identity.0.principal_id
  role_definition_name = "AcrPull"
  scope                = var.container_registry_id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs_usgov" {
  name                       = azurerm_linux_web_app.enrichmentapp.name
  target_resource_id         = azurerm_linux_web_app.enrichmentapp.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  enabled_log  {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  
  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceFileAuditLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_private_endpoint" "privateEnrichmentEndpoint" {
  name                          = "pend-${var.resource_name_suffix}-app-enrichment"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "nic-${var.resource_name_suffix}-app-enrichment"
  tags                          = var.tags
  private_dns_zone_group {
    name = "privatednszonegroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  private_service_connection {
    name = "enrichementprivateendpointconnection"
    private_connection_resource_id = azurerm_linux_web_app.enrichmentapp.id
    subresource_names = ["sites"]
    is_manual_connection = false
  }
}

resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id        = var.keyVaultId
  tenant_id           = azurerm_linux_web_app.enrichmentapp.identity.0.tenant_id
  object_id           = azurerm_linux_web_app.enrichmentapp.identity.0.principal_id
  secret_permissions  = [
    "Get",
    "List"
  ]
}