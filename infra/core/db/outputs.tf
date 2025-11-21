output "CosmosDBEndpointURL" {
  value = azurerm_cosmosdb_account.cosmosdb_account.endpoint
}

output "CosmosDBLogDatabaseName" {
  value = azurerm_cosmosdb_sql_database.log_database.name
}

output "CosmosDBLogContainerName" {
  value = azurerm_cosmosdb_sql_container.log_container.name
}

output "privateEndpointId" {
  value = azurerm_private_endpoint.cosmosPrivateEndpoint.id
}

output "id" {
  value = azurerm_cosmosdb_account.cosmosdb_account.id
}

output "name" {
  value = azurerm_cosmosdb_account.cosmosdb_account.name
}