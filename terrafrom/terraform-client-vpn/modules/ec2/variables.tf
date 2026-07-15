###############################################
# Project
###############################################

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

###############################################
# EC2
###############################################

variable "instance_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "private_ip" {
  type    = string
  default = null
}

variable "key_name" {
  type    = string
  default = null
}

variable "iam_instance_profile" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "associate_public_ip_address" {
  type    = bool
  default = false
}

###############################################
# Root Volume
###############################################

variable "root_volume_size" {
  type = number
}

variable "root_volume_type" {
  type = string
}

variable "delete_on_termination" {
  type = bool
}

variable "encrypted" {
  type = bool
}

###############################################
# Monitoring
###############################################

variable "monitoring" {
  type = bool
}

variable "disable_api_termination" {
  type = bool
}

variable "ebs_optimized" {
  type = bool
}

###############################################
# User Data
###############################################

variable "user_data" {
  type    = string
  default = null
}

###############################################
# Tags
###############################################

variable "tags" {
  type = map(string)
}
