resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  lifecycle {
    ignore_changes = [
      default_outbound_access_enabled
    ]
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    for subnet_name, subnet in var.subnets :
    subnet_name => subnet
    if try(subnet.network_security_group, null) != null
  }

  subnet_id = azurerm_subnet.this[each.key].id

  network_security_group_id = var.network_security_group_ids[
    each.value.network_security_group
  ]
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    for subnet_name, subnet in var.subnets :
    subnet_name => subnet
    if try(subnet.route_table, null) != null
  }

  subnet_id = azurerm_subnet.this[each.key].id

  route_table_id = var.route_table_ids[
    each.value.route_table
  ]
}
