###############################################################################
# Account Outputs
###############################################################################

output "network_account_id" {
  description = "AWS Network account ID"
  value       = var.network_account_id
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "organization_id" {
  description = "AWS Organizations ID"
  value       = var.organization_id
}

###############################################################################
# IPAM Outputs
###############################################################################

output "ipam_id" {
  description = "Enterprise IPAM ID"
  value       = aws_vpc_ipam.enterprise.id
}

output "ipam_arn" {
  description = "Enterprise IPAM ARN"
  value       = aws_vpc_ipam.enterprise.arn
}

###############################################################################
# IPAM Pool Outputs
###############################################################################

output "enterprise_private_pool_id" {
  description = "Enterprise private IPAM pool ID"
  value       = aws_vpc_ipam_pool.enterprise_private.id
}

output "enterprise_us_east_1_pool_id" {
  description = "Enterprise us-east-1 IPAM pool ID"
  value       = aws_vpc_ipam_pool.enterprise_us_east_1.id
}

###############################################################################
# Core VPC Outputs
###############################################################################

output "network_core_vpc_id" {
  description = "Core Network VPC ID"
  value       = aws_vpc.network_core.id
}

output "network_core_vpc_cidr" {
  description = "Core Network VPC CIDR"
  value       = aws_vpc.network_core.cidr_block
}

output "network_core_igw_id" {
  description = "Core Network Internet Gateway ID"
  value       = aws_internet_gateway.network_core.id
}

############################################
# Azure ↔ AWS Connectivity Outputs
############################################

output "azure_customer_gateway_01_id" {
  description = "Azure Customer Gateway 01"
  value       = aws_customer_gateway.azure_01.id
}

output "azure_customer_gateway_02_id" {
  description = "Azure Customer Gateway 02"
  value       = aws_customer_gateway.azure_02.id
}

output "azure_vpn_connection_01_id" {
  description = "Azure VPN Connection 01"
  value       = aws_vpn_connection.azure_01.id
}

output "azure_vpn_connection_02_id" {
  description = "Azure VPN Connection 02"
  value       = aws_vpn_connection.azure_02.id
}
