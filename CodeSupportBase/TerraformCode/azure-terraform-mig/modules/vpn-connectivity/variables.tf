variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "public_ip_name" {
  type = string
}

variable "gateway_name" {
  type = string
}

variable "gateway_sku" {
  type = string
}

variable "gateway_generation" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "gateway_subnet_name" {
  type    = string
  default = "GatewaySubnet"
}

variable "local_gateway_name" {
  type = string
}

variable "remote_gateway_ip" {
  type = string
}

variable "remote_address_prefixes" {
  type = list(string)
}

variable "connection_name" {
  type = string
}

variable "shared_key" {
  type      = string
  sensitive = true
}
