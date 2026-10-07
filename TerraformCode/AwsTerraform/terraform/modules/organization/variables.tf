variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "management_account_id" {
  description = "AWS Organizations management account ID"
  type        = string
}

variable "organizational_units" {
  description = "Organizational Units"
  type = map(object({
    name      = string
    parent_id = optional(string)
  }))
}

variable "accounts" {
  description = "AWS Organization member accounts"
  type = map(object({
    name      = string
    email     = string
    parent_id = string
  }))
}

variable "service_control_policies" {
  description = "Service Control Policies"
  type = map(object({
    name        = string
    description = string
    content     = any
    targets     = list(string)
  }))
}
