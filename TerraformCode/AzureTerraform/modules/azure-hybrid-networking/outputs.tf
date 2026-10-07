###############################################################################
# Azure Hybrid Networking Outputs
###############################################################################

output "resource_group_id" {
  description = "Azure Resource Group ID"
  value       = azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = azurerm_resource_group.this.name
}


###############################################################################
# VNet
###############################################################################

output "vnet_id" {
  description = "Azure VNet ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Azure VNet name"
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "Azure VNet address space"
  value       = azurerm_virtual_network.this.address_space
}


###############################################################################
# Subnets
###############################################################################

output "workload_subnet_id" {
  description = "Azure workload subnet ID"
  value       = azurerm_subnet.workload.id
}

output "workload_subnet_name" {
  description = "Azure workload subnet name"
  value       = azurerm_subnet.workload.name
}

output "gateway_subnet_id" {
  description = "Azure GatewaySubnet ID"
  value       = azurerm_subnet.gateway.id
}


###############################################################################
# Public IPs
###############################################################################

output "vpn_gateway_public_ip_01" {
  description = "Azure VPN Gateway instance 01 public IP"
  value       = azurerm_public_ip.vpn_gateway_01.ip_address
}

output "vpn_gateway_public_ip_02" {
  description = "Azure VPN Gateway instance 02 public IP"
  value       = azurerm_public_ip.vpn_gateway_02.ip_address
}

output "vpn_gateway_public_ip_01_id" {
  description = "Azure VPN Gateway instance 01 public IP resource ID"
  value       = azurerm_public_ip.vpn_gateway_01.id
}

output "vpn_gateway_public_ip_02_id" {
  description = "Azure VPN Gateway instance 02 public IP resource ID"
  value       = azurerm_public_ip.vpn_gateway_02.id
}


###############################################################################
# VPN Gateway
###############################################################################

output "vpn_gateway_id" {
  description = "Azure Virtual Network Gateway ID"
  value       = azurerm_virtual_network_gateway.this.id
}

output "vpn_gateway_name" {
  description = "Azure Virtual Network Gateway name"
  value       = azurerm_virtual_network_gateway.this.name
}

output "vpn_gateway_sku" {
  description = "Azure VPN Gateway SKU"
  value       = azurerm_virtual_network_gateway.this.sku
}


###############################################################################
# Local Network Gateways
###############################################################################

output "aws_local_network_gateway_ids" {
  description = "Azure Local Network Gateway IDs representing AWS VPN tunnels"

  value = {
    for key, gateway in azurerm_local_network_gateway.aws :
    key => gateway.id
  }
}


###############################################################################
# VPN Connections
###############################################################################

output "aws_vpn_connection_ids" {
  description = "Azure VPN connection IDs to AWS"

  value = {
    for key, connection in azurerm_virtual_network_gateway_connection.aws :
    key => connection.id
  }
}
