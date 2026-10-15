output "ids" {
  value = {
    for name, route_table in azurerm_route_table.this :
    name => route_table.id
  }
}
