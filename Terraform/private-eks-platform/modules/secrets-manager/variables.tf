variable "secret_name" {
  description = "Name of the Secrets Manager secret."
  type        = string
}

variable "description" {
  description = "Description of the secret."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ID or ARN used to encrypt the secret."
  type        = string
}

variable "recovery_window_in_days" {
  description = "Number of days before a deleted secret is permanently deleted."
  type        = number

  default = 30

  validation {
    condition     = var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30
    error_message = "recovery_window_in_days must be between 7 and 30."
  }
}

variable "tags" {
  description = "Tags to apply to the secret."
  type        = map(string)
  default     = {}
}
