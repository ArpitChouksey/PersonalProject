variable "role_name" {
  type = string
}

variable "role_description" {
  type    = string
  default = null
}

variable "instance_profile_name" {
  type = string
}

variable "s3_policy_name" {
  type = string
}

variable "secrets_manager_policy_name" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "secret_policy_resource" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
