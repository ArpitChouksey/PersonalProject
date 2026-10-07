variable "account_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "enable_config" {
  type    = bool
  default = false
}

variable "enable_cloudtrail" {
  type    = bool
  default = false
}
