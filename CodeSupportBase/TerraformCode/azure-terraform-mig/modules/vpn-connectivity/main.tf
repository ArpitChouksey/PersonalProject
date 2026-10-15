
data "azurerm_subnet" "gateway" {
  name                 = var.gateway_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_public_ip" "this" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"
  zones             = ["1", "2", "3"]

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type       = "Vpn"
  vpn_type   = "RouteBased"
  sku        = var.gateway_sku
  generation = var.gateway_generation

  active_active = false
  bgp_enabled   = false

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.gateway.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_local_network_gateway" "this" {
  name                = var.local_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  gateway_address = var.remote_gateway_ip
  address_space   = var.remote_address_prefixes
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  name                = var.connection_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.this.id
  shared_key                 = var.shared_key
  connection_protocol        = "IKEv2"
}

