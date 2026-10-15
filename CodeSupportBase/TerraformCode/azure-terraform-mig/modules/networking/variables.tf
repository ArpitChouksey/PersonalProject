variable "resource_group_name" {
  description = "Resource group containing the VNet"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
}

variable "subnets" {
  description = "Subnet configuration"

  type = map(object({
    address_prefixes                              = list(string)
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    default_outbound_access_enabled               = optional(bool, true)
    network_security_group                        = optional(string)
    route_table                                   = optional(string)
  }))
}

variable "network_security_group_ids" {
  description = "Map of NSG names to IDs"
  type        = map(string)
  default     = {}
}

variable "route_table_ids" {
  description = "Map of route table names to IDs"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "VNet tags"
  type        = map(string)
  default     = {}
}
