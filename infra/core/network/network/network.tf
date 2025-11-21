terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.3.0"
      configuration_aliases = [azurerm.infra_internal]
    }
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.resource_name_suffix}"
  location            = var.location
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.enabledDDOSProtectionPlan ? var.ddos_plan_id == "" ? 1 : 0 : 0
  name                = "ddos-${var.resource_name_suffix}"
  resource_group_name = var.resourceGroupName
  location            = var.location
} 

resource "azurerm_virtual_network" "ia" {
  name                = "vnet-${var.resource_name_suffix}"
  location            = var.location
  resource_group_name = var.resourceGroupName
  address_space       = [var.vnetIpAddressCIDR]
  tags                = var.tags
}

resource "azurerm_subnet" "ampls" {
  name                                          = "snet-${var.resource_name_suffix}-ampls"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetAzureMonitorCIDR]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "storage" {
  name                                          = "snet-${var.resource_name_suffix}-storage"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetStorageAccountCIDR]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "cosmos" {
  name                                          = "snet-${var.resource_name_suffix}-cosmos"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetCosmosDbCIDR]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "azureAi" {
  name                                          = "snet-${var.resource_name_suffix}-azureai"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetAzureAiCIDR]
  service_endpoints                             = ["Microsoft.CognitiveServices"]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "keyVault" {
  name                                          = "snet-${var.resource_name_suffix}-keyvault"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetKeyVaultCIDR]
  service_endpoints                             = ["Microsoft.KeyVault"]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "app" {
  name                                          = "snet-${var.resource_name_suffix}-app"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetAppCIDR]
  service_endpoints                             = ["Microsoft.Storage"]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "function" {
  name                                          = "snet-${var.resource_name_suffix}-function"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetFunctionCIDR]
  service_endpoints                             = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "enrichment" {
  name                                          = "snet-${var.resource_name_suffix}-enrichment"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetEnrichmentCIDR]
  service_endpoints                             = ["Microsoft.Storage"]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "integration" {
  name                                          = "snet-${var.resource_name_suffix}-integration"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetIntegrationCIDR]
  service_endpoints                             = ["Microsoft.Storage"]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
  delegation {
    name = "integrationDelegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "aiSearch" {
  name                                          = "snet-${var.resource_name_suffix}-aisearch"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetSearchServiceCIDR]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "openai" {
  name                                          = "snet-${var.resource_name_suffix}-openai"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetAzureOpenAICIDR]
  service_endpoints                             = ["Microsoft.CognitiveServices"]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "acr" {
  name                                          = "snet-${var.resource_name_suffix}-acr"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetACRCIDR]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "dns" {
  name                                          = "snet-${var.resource_name_suffix}-dns"
  resource_group_name                           = var.resourceGroupName
  virtual_network_name                          = azurerm_virtual_network.ia.name
  address_prefixes                              = [var.snetDnsCIDR]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
  delegation {
    name = "dnsDelegation"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

data "azurerm_virtual_network" "int" {
  provider            = azurerm.infra_internal
  name                = "ERDCRDEDMZ-VNET"
  resource_group_name = "Network"
}

resource "azurerm_virtual_network_peering" "ia_to_int" {
  name                         = "peer-${var.resource_name_suffix}"
  resource_group_name          = azurerm_virtual_network.ia.resource_group_name
  virtual_network_name         = azurerm_virtual_network.ia.name
  remote_virtual_network_id    = data.azurerm_virtual_network.int.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "int_to_ia" {
  provider                     = azurerm.infra_internal
  name                         = "peer-${var.resource_name_suffix}"
  resource_group_name          = data.azurerm_virtual_network.int.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.int.name
  remote_virtual_network_id    = azurerm_virtual_network.ia.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}