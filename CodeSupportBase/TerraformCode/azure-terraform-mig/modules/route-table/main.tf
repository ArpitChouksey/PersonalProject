resource "azurerm_route_table" "this" {
  for_each = var.route_tables

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_route" "this" {
  for_each = {
    for item in flatten([
      for route_table_name, route_table in var.route_tables : [
        for route_name, route in route_table.routes : {
          key            = "${route_table_name}.${route_name}"
          route_table    = route_table_name
          route_name     = route_name
          address_prefix = route.address_prefix
          next_hop_type  = route.next_hop_type
          next_hop_ip    = try(route.next_hop_in_ip_address, null)
        }
      ]
    ]) : item.key => item
  }

  name                   = each.value.route_name
  resource_group_name    = var.resource_group_name
  route_table_name       = each.value.route_table
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_ip
}
