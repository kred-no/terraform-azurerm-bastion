////////////////////////
// Outputs
////////////////////////

output "connection_info" {
  sensitive = false

  value = {
    bastion_dns_name  = azurerm_bastion_host.MAIN.dns_name
    public_ip_address = azurerm_public_ip.MAIN.ip_address
  }
}

output "subnet" {
  sensitive = false
  value     = azurerm_subnet.MAIN
}

output "azurerm_network_security_group" {
  sensitive = false
  value     = one(azurerm_network_security_group.MAIN[*])
}
