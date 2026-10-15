output "public_ip_address" {
  value = azurerm_public_ip.this.ip_address
}

output "gateway_id" {
  value = azurerm_virtual_network_gateway.this.id
}

output "local_gateway_id" {
  value = azurerm_local_network_gateway.this.id
}

output "connection_id" {
  value = azurerm_virtual_network_gateway_connection.this.id
}
