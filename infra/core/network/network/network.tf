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
  arm_file_path = var.enabledDDOSProtectionPlan ? "arm_templates/network/vnet_w_ddos.template.json" : "arm_templates/network/vnet.template.json"
}

# Create the Bing Search instance via ARM Template
data "template_file" "workflow" {
  template = file(local.arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

//Create the Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

//Create the DDoS plan
resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.enabledDDOSProtectionPlan ? var.ddos_plan_id == "" ? 1 : 0 : 0
  name                = var.ddos_name
  resource_group_name = var.resourceGroupName
  location            = var.location
} 

//Create the Virtual Network
resource "azurerm_resource_group_template_deployment" "vnet_w_subnets" {
  resource_group_name = var.resourceGroupName
  parameters_content = jsonencode({
    "name"                      = { value = "${var.vnet_name}" },
    "location"                  = { value = "${var.location}" },
    "tags"                      = { value = var.tags },
    "ddos_plan_id"              = { value = "${var.enabledDDOSProtectionPlan ? var.ddos_plan_id == "" ? azurerm_network_ddos_protection_plan.ddos[0].id : var.ddos_plan_id : ""}" },
    "nsg_name"                  = { value = "${azurerm_network_security_group.nsg.name}" },
    "vnet_CIDR"                 = { value = "${var.vnetIpAddressCIDR}" },
    "subnet_AzureMonitor_CIDR"  = { value = "${var.snetAzureMonitorCIDR}" },
    "subnet_AzureStorage_CIDR"  = { value = "${var.snetStorageAccountCIDR}" },
    "subnet_AzureCosmosDB_CIDR" = { value = "${var.snetCosmosDbCIDR}" },
    "subnet_AzureAi_CIDR"       = { value = "${var.snetAzureAiCIDR}" },
    "subnet_KeyVault_CIDR"      = { value = "${var.snetKeyVaultCIDR}" },
    "subnet_App_CIDR"           = { value = "${var.snetAppCIDR}" },
    "subnet_Function_CIDR"      = { value = "${var.snetFunctionCIDR}" },
    "subnet_Enrichment_CIDR"    = { value = "${var.snetEnrichmentCIDR}" },
    "subnet_Integration_CIDR"   = { value = "${var.snetIntegrationCIDR}" },
    "subnet_AiSearch_CIDR"      = { value = "${var.snetSearchServiceCIDR}" },
    "subnet_AzureOpenAI_CIDR"   = { value = "${var.snetAzureOpenAICIDR}" },
    "subnet_Acr_CIDR"           = { value = "${var.snetACRCIDR}" },
    "subnet_Dns_CIDR"           = { value = "${var.snetDnsCIDR}" },
    "privateEndpointNetworkPoliciesStatus" = { value = "${var.azure_environment == "AzureUSGovernment" ? "Disabled" : "Enabled"}" },
    "privateLinkServiceNetworkPoliciesStatus" = { value = "${var.azure_environment == "AzureUSGovernment" ? "Disabled" : "Enabled"}" },
  })
  template_content = data.template_file.workflow.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "vnet-${filemd5(local.arm_file_path)}"
  deployment_mode = "Incremental"
}

data "azurerm_virtual_network" "ia" {
  depends_on          = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                = var.vnet_name
  resource_group_name = var.resourceGroupName
}

data "azurerm_virtual_network" "int" {
  provider            = azurerm.infra_internal
  name                = "ERDCRDEDMZ-VNET"
  resource_group_name = "Network"
}

resource "azurerm_virtual_network_peering" "ia_to_int" {
  name                         = "peer-${var.vnet_name}"
  resource_group_name          = data.azurerm_virtual_network.ia.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.ia.name
  remote_virtual_network_id    = data.azurerm_virtual_network.int.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "int_to_ia" {
  provider                     = azurerm.infra_internal
  name                         = "peer-${var.vnet_name}"
  resource_group_name          = data.azurerm_virtual_network.int.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.int.name
  remote_virtual_network_id    = data.azurerm_virtual_network.ia.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}


data "azurerm_subnet" "ampls" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "ampls"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "storageAccount" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "storageAccount"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "cosmosDb" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "cosmosDb"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "azureAi" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "azureAi"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "keyVault" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "keyVault"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "app" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "app"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "function" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "function"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "enrichment" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "enrichment"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "integration" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "integration"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "aiSearch" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "aiSearch"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "azureOpenAI" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "azureOpenAI"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

data "azurerm_subnet" "acr" {
  depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
  name                 = "acr"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

# resource "azurerm_private_dns_resolver" "private_dns_resolver" {
#     name                = var.dns_resolver_name
#     location            = var.location
#     resource_group_name = var.resourceGroupName
#     virtual_network_id  = jsondecode(azurerm_resource_group_template_deployment.vnet_w_subnets.output_content).id.value
#     tags                = var.tags
#     depends_on = [ azurerm_resource_group_template_deployment.vnet_w_subnets ]
# }

# resource "azurerm_private_dns_resolver_inbound_endpoint" "private_dns_resolver" {
#     name                        = "dns-resolver-inbound-endpoint"
#     location                    = var.location
#     private_dns_resolver_id     = azurerm_private_dns_resolver.private_dns_resolver.id
#     tags                        = var.tags
#     ip_configurations {
#       subnet_id                 = jsondecode(azurerm_resource_group_template_deployment.vnet_w_subnets.output_content).dnsSubnetId.value   
#     }

#     depends_on = [ azurerm_private_dns_resolver.private_dns_resolver ]
# }