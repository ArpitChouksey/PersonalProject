###############################################################################
# Resource Group
###############################################################################

output "resource_group_id" {
  description = "Azure resource group ID"
  value       = module.azure_hybrid_networking.resource_group_id
}

output "resource_group_name" {
  description = "Azure resource group name"
  value       = module.azure_hybrid_networking.resource_group_name
}


###############################################################################
# VNet
###############################################################################

output "vnet_id" {
  description = "Azure VNet ID"
  value       = module.azure_hybrid_networking.vnet_id
}

output "vnet_name" {
  description = "Azure VNet name"
  value       = module.azure_hybrid_networking.vnet_name
}


###############################################################################
# Subnets
###############################################################################

output "workload_subnet_id" {
  description = "Azure workload subnet ID"
  value       = module.azure_hybrid_networking.workload_subnet_id
}

output "gateway_subnet_id" {
  description = "Azure GatewaySubnet ID"
  value       = module.azure_hybrid_networking.gateway_subnet_id
}


###############################################################################
# VPN Gateway
###############################################################################

output "vpn_gateway_id" {
  description = "Azure VPN gateway ID"
  value       = module.azure_hybrid_networking.vpn_gateway_id
}

output "vpn_gateway_name" {
  description = "Azure VPN gateway name"
  value       = module.azure_hybrid_networking.vpn_gateway_name
}

output "vpn_gateway_sku" {
  description = "Azure VPN gateway SKU"
  value       = module.azure_hybrid_networking.vpn_gateway_sku
}


###############################################################################
# VPN Gateway Public IPs
###############################################################################

output "vpn_gateway_public_ip_01" {
  description = "Azure VPN gateway public IP 01"
  value       = module.azure_hybrid_networking.vpn_gateway_public_ip_01
}

output "vpn_gateway_public_ip_02" {
  description = "Azure VPN gateway public IP 02"
  value       = module.azure_hybrid_networking.vpn_gateway_public_ip_02
}


###############################################################################
# AWS Local Network Gateways
###############################################################################

output "aws_local_network_gateway_ids" {
  description = "Azure Local Network Gateway IDs for AWS"
  value       = module.azure_hybrid_networking.aws_local_network_gateway_ids
}


###############################################################################
# AWS VPN Connections
###############################################################################

output "aws_vpn_connection_ids" {
  description = "Azure VPN connection IDs to AWS"
  value       = module.azure_hybrid_networking.aws_vpn_connection_ids
}
