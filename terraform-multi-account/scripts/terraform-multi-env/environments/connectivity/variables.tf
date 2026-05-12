variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "terraform_execution_role" {
  description = "Cross-account Terraform execution role"
  type        = string
}

variable "vpc_cidr" {
  description = "Connectivity VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}
