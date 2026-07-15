####################################
# AWS
####################################

variable "aws_region" {
  type = string
}

####################################
# Project
####################################

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

####################################
# Networking
####################################

variable "vpc_cidr" {
  type = string
}

variable "enable_dns_support" {
  type = bool
}

variable "enable_dns_hostnames" {
  type = bool
}

variable "app_subnet_cidr" {
  type = string
}

variable "db_subnet_cidr" {
  type = string
}

variable "app_subnet_az" {
  type = string
}

variable "db_subnet_az" {
  type = string
}

####################################
# VPN
####################################

variable "vpn_cidr" {
  type = string
}

####################################
# EC2
####################################

variable "windows_ami" {
  type = string
}

variable "linux_ami" {
  type = string
}

variable "windows_instance_type" {
  type = string
}

variable "linux_instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

####################################
# Tags
####################################

variable "tags" {

  type = map(string)

}


####################################
# Common EC2
####################################

variable "root_volume_type" {
  type = string
}

####################################
# Windows
####################################

variable "windows_instance_name" {
  type = string
}

variable "windows_private_ip" {
  type = string
}

variable "windows_root_volume_size" {
  type = number
}

####################################
# Linux
####################################

variable "linux_instance_name" {
  type = string
}

variable "linux_private_ip" {
  type = string
}

variable "linux_root_volume_size" {
  type = number
}

####################################
# VPN
####################################

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
  type = list(string)
}

variable "authorize_all_groups" {
  type = bool
}
