###########################################
# Project
###########################################

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

###########################################
# IAM
###########################################

variable "role_name" {
  description = "IAM Role Name"
  type        = string
}

variable "instance_profile_name" {
  description = "Instance Profile Name"
  type        = string
}

###########################################
# Tags
###########################################

variable "tags" {
  description = "Common Tags"
  type        = map(string)
}
