###########################################
# Project
###########################################

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

###########################################
# VPC
###########################################

variable "vpc_cidr" {
  type = string
}

variable "enable_dns_support" {
  type = bool
}

variable "enable_dns_hostnames" {
  type = bool
}

###########################################
# Application Subnet
###########################################

variable "app_subnet_cidr" {
  type = string
}

variable "app_subnet_az" {
  type = string
}

###########################################
# Database Subnet
###########################################

variable "db_subnet_cidr" {
  type = string
}

variable "db_subnet_az" {
  type = string
}

###########################################
# Tags
###########################################

variable "tags" {
  type = map(string)
}
