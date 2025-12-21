variable "alb_sg_id" {
  type        = string
  description = "ALB security group ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ALB"
}


#variable "public_sg_id" {
#  description = "Existing Public Security Group ID"
#  type        = string
#}

variable "app_sg_id" {
  description = "Existing App Security Group ID"
  type        = string
}

variable "db_sg_id" {
  description = "Existing DB Security Group ID"
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


variable "vpc_id" {
  type = string
}

variable "igw_id" {
  description = "Internet Gateway ID for public route"
  type        = string
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "tags" {
  type = map(string)
}

