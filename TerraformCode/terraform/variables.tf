variable "app_ami_id" {
  type = string
}

variable "app_instance_type" {
  type = string
}

variable "app_subnet_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "app_instance_name" {
  type = string
}


################################
# GLOBAL
################################
variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

################################
# NETWORK (EXISTING)
################################
variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "igw_id" {
  description = "Existing Internet Gateway ID"
  type        = string
}

variable "nat_gateway_id" {
  description = "Existing NAT Gateway ID"
  type        = string
}

variable "private_route_table_id" {
  description = "Existing private route table ID"
  type        = string
}

################################
# SUBNET DEFINITIONS
################################
variable "public_subnets" {
  description = "Public subnet definitions"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "Private subnet definitions"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (used by ALB)"
  type        = list(string)
}

################################
# SECURITY GROUP IDS (EXISTING)
################################
variable "alb_sg_id" {
  description = "ALB security group ID"
  type        = string
}

#variable "app_sg_id" {
#  description = "Application security group ID"
#  type        = string
#}

variable "db_sg_id" {
  description = "Database security group ID"
  type        = string
}

