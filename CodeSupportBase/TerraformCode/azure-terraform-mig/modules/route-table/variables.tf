variable "resource_group_name" {
  description = "Resource group containing route tables"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
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

variable "tags" {
  description = "Common route table tags"
  type        = map(string)
  default     = {}
}
