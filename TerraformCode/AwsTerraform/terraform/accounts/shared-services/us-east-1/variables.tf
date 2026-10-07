variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "sharedservices"
}

variable "vpc_cidr" {
  description = "Shared Services VPC CIDR"
  type        = string
}

variable "vpc_name" {
  description = "Shared Services VPC name"
  type        = string
}

variable "subnets" {
  description = "Shared Services private subnets"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
}

variable "route_table_name" {
  description = "Private route table name"
  type        = string
}

variable "transit_gateway_id" {
  description = "Enterprise Transit Gateway ID"
  type        = string
}

variable "transit_gateway_attachment_name" {
  description = "TGW attachment name"
  type        = string
}

variable "routes" {
  description = "Routes from Shared Services VPC to other enterprise networks"
  type = map(object({
    destination_cidr = string
  }))
}
