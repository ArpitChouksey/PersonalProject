output "ids" {
  value = {
    for name, nsg in azurerm_network_security_group.this :
    name => nsg.id
  }
}
