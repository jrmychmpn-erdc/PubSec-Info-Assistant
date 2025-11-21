resource "azurerm_cognitive_account" "cognitiveService" {
  name                          = "cog-${var.resource_name_suffix}"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  kind                          = "CognitiveServices"
  sku_name                      = var.sku["name"]
  tags                          = var.tags
  custom_subdomain_name         = "cog-${var.resource_name_suffix}"
  public_network_access_enabled = false
}

module "cog_service_key" {
  source                        = "../../security/keyvaultSecret"
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  key_vault_name                = var.key_vault_name
  resourceGroupName             = var.resourceGroupName
  secret_name                   = "AZURE-AI-KEY"
  secret_value                  = azurerm_cognitive_account.cognitiveService.primary_access_key
  alias                         = "aisvckey"
  tags                          = var.tags
  kv_secret_expiration          = var.kv_secret_expiration
  contentType                   = "application/vnd.bag-StrongEncPasswordString"
}

resource "azurerm_private_endpoint" "accountPrivateEndpoint" {
  name                          = "pend-${var.resource_name_suffix}-cog"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "nic-${var.resource_name_suffix}-cog"
  tags                          = var.tags

  private_service_connection {
    name                           = "pend-${var.resource_name_suffix}-cog"
    private_connection_resource_id = azurerm_cognitive_account.cognitiveService.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids

  }
}