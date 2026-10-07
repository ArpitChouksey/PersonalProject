###############################################################################
# Account Configuration
###############################################################################

variable "account_name" {
  description = "AWS account name"
  type        = string
  default     = "network"
}

###############################################################################
# AWS Region
###############################################################################

variable "aws_region" {
  description = "AWS region for the network account"
  type        = string
  default     = "us-east-1"
}

###############################################################################
# Environment
###############################################################################

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "enterprise"
}

###############################################################################
# Project
###############################################################################

variable "project" {
  description = "Project name"
  type        = string
  default     = "master-networking"
}

###############################################################################
# AWS Network Account
###############################################################################

variable "network_account_id" {
  description = "AWS Network account ID"
  type        = string
  default     = "360734036001"
}

###############################################################################
# AWS Organizations
###############################################################################

variable "organization_id" {
  description = "AWS Organizations ID"
  type        = string
  default     = "o-tiz1ddrmwn"
}


############################################
# Azure ↔ AWS Connectivity
############################################

variable "transit_gateway_id" {
  description = "AWS Transit Gateway ID used for Azure connectivity"
  type        = string
}

variable "azure_bgp_asn" {
  description = "Azure VPN Gateway BGP ASN"
  type        = number
}

variable "azure_vpn_gateway_public_ip_01" {
  description = "Azure VPN Gateway public IP 01"
  type        = string
}

variable "azure_vpn_gateway_public_ip_02" {
  description = "Azure VPN Gateway public IP 02"
  type        = string
}
