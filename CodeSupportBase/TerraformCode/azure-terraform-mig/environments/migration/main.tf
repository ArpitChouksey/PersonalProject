module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network_security_group" {
  source = "../../modules/network-security-group"

  resource_group_name     = var.resource_group_name
  location                = var.location
  network_security_groups = var.network_security_groups
}

module "route_table" {
  source = "../../modules/route-table"

  resource_group_name = var.resource_group_name
  location            = var.location
  route_tables        = var.route_tables
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = var.vnet_name
  address_space       = var.address_space
  subnets             = var.subnets
  tags                = var.tags

  network_security_group_ids = module.network_security_group.ids
  route_table_ids            = module.route_table.ids
}

module "vpn_connectivity" {
  source = "../../modules/vpn-connectivity"

  resource_group_name     = var.resource_group_name
  location                = var.location
  public_ip_name          = var.vpn_public_ip_name
  gateway_name            = var.vpn_gateway_name
  gateway_sku             = var.vpn_gateway_sku
  gateway_generation      = var.vpn_gateway_generation
  vnet_name               = var.vnet_name
  gateway_subnet_name     = "GatewaySubnet"
  local_gateway_name      = var.vpn_local_gateway_name
  remote_gateway_ip       = var.vpn_remote_gateway_ip
  remote_address_prefixes = var.vpn_remote_address_prefixes
  connection_name         = var.vpn_connection_name
  shared_key              = var.vpn_shared_key
}
