variable "aws_region" {
  description = "AWS region where IAM Identity Center is configured"
  type        = string
  default     = "us-east-1"
}

variable "identity_store_id" {
  description = "IAM Identity Center Identity Store ID"
  type        = string
}

variable "permission_sets" {
  description = "IAM Identity Center permission sets"

  type = map(object({
    name             = string
    description      = string
    session_duration = string
    tags             = map(string)
  }))
}

variable "users" {
  description = "IAM Identity Center users"

  type = map(object({
    user_name    = string
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
  }))
}

variable "account_assignments" {
  description = "IAM Identity Center account assignments"

  type = map(object({
    account_id         = string
    permission_set_key = string
    user_key           = string
  }))
}
