variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  description = "Shared VPC ID from connectivity-account"
}

variable "public_subnet_az1" {}
variable "public_subnet_az2" {}

variable "private_subnet_az1" {}
variable "private_subnet_az2" {}
