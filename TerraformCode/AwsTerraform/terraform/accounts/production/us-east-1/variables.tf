variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "Production VPC CIDR"
  type        = string
}

variable "vpc_name" {
  description = "Production VPC name"
  type        = string
}

variable "subnets" {
  description = "Production private subnets"

  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
}

variable "route_table_name" {
  description = "Production private route table"
  type        = string
}

variable "transit_gateway_id" {
  description = "Enterprise Transit Gateway ID"
  type        = string
}

variable "transit_gateway_attachment_name" {
  description = "Production TGW attachment name"
  type        = string
}

variable "routes" {
  description = "Routes from Production VPC to enterprise networks"

  type = map(object({
    destination_cidr = string
  }))
}
