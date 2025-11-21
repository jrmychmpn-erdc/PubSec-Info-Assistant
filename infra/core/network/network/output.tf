output "nsg_name" {
  value = azurerm_network_security_group.nsg.name  
}

output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
}

output "vnet_name" {
  value = azurerm_virtual_network.ia.name
}

output "vnet_id" {
  value = azurerm_virtual_network.ia.id
}

output "snetAmpls_name" {
  value = azurerm_subnet.ampls.name
}

output "snetStorage_id" {
  value = azurerm_subnet.storage.id
}

output "snetCosmosDb_id" {
  value = azurerm_subnet.cosmos.id
}

output "snetAzureAi_id" {
  value = azurerm_subnet.azureAi.id
}

output "snetKeyVault_id" {
  description = "The ID of the subnet dedicated for the Key Vault"
  value = azurerm_subnet.keyVault.id
}

output "snetKeyVault_name" {
  value = azurerm_subnet.keyVault.name
}

output "snetACR_id" {
  value = azurerm_subnet.acr.id
}

output "snetApp_id" {
  value = azurerm_subnet.app.id
}

output "snetApp_name" {
  value = azurerm_subnet.app.name
}

output "snetFunction_id" {
  value = azurerm_subnet.function.id
}

output "snetFunction_name" {
  value = azurerm_subnet.function.name
}

output "snetEnrichment_id" {
  value = azurerm_subnet.enrichment.id
}

output "snetIntegration_id" {
  value = azurerm_subnet.integration.id
}

output "snetIntegration_name" {
  value = azurerm_subnet.integration.name
}

output "snetSearch_id" {
  value = azurerm_subnet.aiSearch.id
}

output "snetAzureOpenAI_id" {
  value = azurerm_subnet.openai.id
}

output "ddos_plan_id" {
  value = var.enabledDDOSProtectionPlan ? var.ddos_plan_id == "" ? azurerm_network_ddos_protection_plan.ddos[0].id : var.ddos_plan_id : ""
}

output "dns_private_resolver_ip" {
  value = "10.208.250.20"
}