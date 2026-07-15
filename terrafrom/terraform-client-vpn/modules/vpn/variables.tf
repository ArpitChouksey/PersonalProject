#########################################
# Project
#########################################

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

#########################################
# Client VPN
#########################################

variable "vpn_name" {
  type = string
}

variable "client_cidr_block" {
  type = string
}

variable "server_certificate_arn" {
  type = string
}

variable "root_certificate_chain_arn" {
  type = string
}

variable "transport_protocol" {
  type = string
}

variable "vpn_port" {
  type = number
}

variable "split_tunnel" {
  type = bool
}

variable "session_timeout_hours" {
  type = number
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

#########################################
# Networking
#########################################

variable "vpc_id" {
  type = string
}

variable "target_subnet_id" {
  type = string
}

variable "destination_cidr_block" {
  type = string
}

#########################################
# Authorization
#########################################

variable "authorize_all_groups" {
  type = bool
}

#########################################
# Tags
#########################################

variable "tags" {
  type = map(string)
}
