variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones used by the environment"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet configuration"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Private subnet configuration"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "enable_dns_support" {
  description = "Enable DNS support"
  type        = bool
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
