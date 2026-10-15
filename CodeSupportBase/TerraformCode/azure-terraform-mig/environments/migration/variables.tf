variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Migration resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "vnet_name" {
  description = "VNet name"
  type        = string
}

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
}

variable "subnets" {
  description = "Generic subnet configuration"

  type = map(object({
    address_prefixes                              = list(string)
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    default_outbound_access_enabled               = optional(bool, true)
    network_security_group                        = optional(string)
    route_table                                   = optional(string)
  }))
}

variable "network_security_groups" {
  description = "Generic NSG configuration"

  type = map(object({
    tags = optional(map(string), {})

    rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
      description                = optional(string)
    })), {})
  }))
}

variable "route_tables" {
  description = "Generic route table configuration"

  type = map(object({
    disable_bgp_route_propagation = optional(bool, false)

    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  }))
}

# VPN connectivity configuration
variable "vpn_public_ip_name" {
  type = string
}

variable "vpn_gateway_name" {
  type = string
}

variable "vpn_gateway_sku" {
  type = string
}

variable "vpn_gateway_generation" {
  type = string
}

variable "vpn_local_gateway_name" {
  type = string
}

variable "vpn_remote_gateway_ip" {
  type = string
}

variable "vpn_remote_address_prefixes" {
  type = list(string)
}

variable "vpn_connection_name" {
  type = string
}

variable "vpn_shared_key" {
  description = "Existing VPN pre-shared key; supply through TF_VAR_vpn_shared_key"
  type        = string
  sensitive   = true
}
