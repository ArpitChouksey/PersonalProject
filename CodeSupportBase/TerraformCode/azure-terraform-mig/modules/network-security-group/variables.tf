variable "resource_group_name" {
  description = "Resource group containing the NSGs"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
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
