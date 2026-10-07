resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space

  tags = var.tags
}

resource "azurerm_subnet" "workload" {
  name                 = var.workload_subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.workload_subnet_address_prefixes

  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.gateway_subnet_address_prefixes
}

resource "azurerm_public_ip" "vpn_gateway_01" {
  name                = var.public_ip_01_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Static"
  sku               = "Standard"

  zones = [
    "1",
    "2",
    "3"
  ]

  tags = var.tags
}

resource "azurerm_public_ip" "vpn_gateway_02" {
  name                = var.public_ip_02_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Static"
  sku               = "Standard"

  zones = [
    "1",
    "2",
    "3"
  ]

  tags = var.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.vpn_gateway_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type       = "Vpn"
  vpn_type   = "RouteBased"
  sku        = var.vpn_gateway_sku
  generation = var.vpn_gateway_generation

  active_active = true
  bgp_enabled   = true

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_01.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  ip_configuration {
    name                          = "activeActive"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_02.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  bgp_settings {
    asn = var.azure_bgp_asn

    peering_addresses {
      ip_configuration_name = "default"

      apipa_addresses = [
        var.azure_bgp_apipa_primary_01,
        var.azure_bgp_apipa_secondary_01
      ]
    }

    peering_addresses {
      ip_configuration_name = "activeActive"

      apipa_addresses = [
        var.azure_bgp_apipa_primary_02,
        var.azure_bgp_apipa_secondary_02
      ]
    }
  }

  tags = var.tags
}

resource "azurerm_local_network_gateway" "aws" {
  for_each = var.aws_local_network_gateways

  name                = each.value.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  gateway_address = each.value.gateway_address
  address_space   = []

  bgp_settings {
    asn                 = each.value.bgp_asn
    bgp_peering_address = each.value.bgp_peering_address
  }

  tags = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "aws" {
  for_each = var.aws_connections

  name                = each.value.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id  = azurerm_local_network_gateway.aws[each.value.local_network_gateway_key].id

  bgp_enabled = true

  shared_key = var.aws_shared_keys[each.key]

  connection_protocol = "IKEv2"

  use_policy_based_traffic_selectors = false

  dpd_timeout_seconds = 45

  custom_bgp_addresses {
    primary   = each.value.custom_bgp_primary
    secondary = each.value.custom_bgp_secondary
  }

  tags = var.tags
}
