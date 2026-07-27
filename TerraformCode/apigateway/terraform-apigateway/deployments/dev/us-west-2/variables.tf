###############################################################
# Deployment Variables — dev / us-west-2
###############################################################

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "enterprise-platform"
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
  default     = "nonprod"
}

variable "owner" {
  description = "Resource Owner"
  type        = string
  default     = "Platform-Team"
}

variable "cost_center" {
  description = "Cost Center"
  type        = string
  default     = "Cloud"
}

variable "business_unit" {
  description = "Business Unit"
  type        = string
  default     = "Engineering"
}

variable "terraform_version" {
  description = "Terraform Version"
  type        = string
  default     = "1.13.4"
}

variable "tags" {
  description = "Additional custom tags applied to every API"
  type        = map(string)
  default     = {}
}
