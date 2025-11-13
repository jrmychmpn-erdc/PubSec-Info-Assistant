output "privateDnsZoneResourceId" {
  value = data.azurerm_private_dns_zone.pr_dns_zone.id
}

output "privateDnsZoneName" {
  value = data.azurerm_private_dns_zone.pr_dns_zone.name
}