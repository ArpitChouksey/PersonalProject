###############################################################################
# Azure Subscription
###############################################################################

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}


###############################################################################
# Resource Group / Location
###############################################################################

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}


###############################################################################
# VNet
###############################################################################

variable "vnet_name" {
  description = "Azure VNet name"
  type        = string
}

variable "vnet_address_space" {
  description = "Azure VNet address space"
  type        = list(string)
}


###############################################################################
# Subnets
###############################################################################

variable "workload_subnet_name" {
  description = "Workload subnet name"
  type        = string
}

variable "workload_subnet_address_prefixes" {
  description = "Workload subnet CIDRs"
  type        = list(string)
}

variable "gateway_subnet_address_prefixes" {
  description = "GatewaySubnet CIDRs"
  type        = list(string)
}


###############################################################################
# Public IPs
###############################################################################

variable "public_ip_01_name" {
  description = "First VPN gateway public IP name"
  type        = string
}

variable "public_ip_02_name" {
  description = "Second VPN gateway public IP name"
  type        = string
}


###############################################################################
# VPN Gateway
###############################################################################

variable "vpn_gateway_name" {
  description = "Azure VPN gateway name"
  type        = string
}

variable "vpn_gateway_sku" {
  description = "Azure VPN gateway SKU"
  type        = string
}

variable "vpn_gateway_generation" {
  description = "Azure VPN gateway generation"
  type        = string
}


###############################################################################
# Azure BGP
###############################################################################

variable "azure_bgp_asn" {
  description = "Azure VPN gateway BGP ASN"
  type        = number
}

variable "azure_bgp_apipa_primary_01" {
  description = "Azure VPN gateway instance 1 primary APIPA"
  type        = string
}

variable "azure_bgp_apipa_secondary_01" {
  description = "Azure VPN gateway instance 1 secondary APIPA"
  type        = string
}

variable "azure_bgp_apipa_primary_02" {
  description = "Azure VPN gateway instance 2 primary APIPA"
  type        = string
}

variable "azure_bgp_apipa_secondary_02" {
  description = "Azure VPN gateway instance 2 secondary APIPA"
  type        = string
}


###############################################################################
# AWS Local Network Gateways
###############################################################################

variable "aws_local_network_gateways" {
  description = "AWS VPN endpoints represented as Azure Local Network Gateways"

  type = map(object({
    name                = string
    gateway_address     = string
    bgp_asn             = number
    bgp_peering_address = string
  }))
}


###############################################################################
# AWS VPN Connections
###############################################################################

variable "aws_connections" {
  description = "Azure VPN connections to AWS"

  type = map(object({
    name                      = string
    local_network_gateway_key = string
    custom_bgp_primary        = string
    custom_bgp_secondary      = string
  }))
}

###############################################################################
# AWS VPN Shared Keys
###############################################################################

variable "aws_shared_keys" {
  description = "IPsec pre-shared keys for AWS VPN connections"

  type      = map(string)
  sensitive = true
}


###############################################################################
# Tags
###############################################################################

variable "tags" {
  description = "Common resource tags"
  type        = map(string)

  default = {}
}
