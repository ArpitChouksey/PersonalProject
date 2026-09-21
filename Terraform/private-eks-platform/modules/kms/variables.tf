variable "alias_name" {
  description = "KMS key alias name."
  type        = string
}

variable "description" {
  description = "Description of the KMS key."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Number of days before a scheduled KMS key deletion."
  type        = number
  default     = 30

  validation {
    condition = (
      var.deletion_window_in_days >= 7 &&
      var.deletion_window_in_days <= 30
    )

    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic annual KMS key rotation."
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Whether the KMS key is a multi-Region key."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the KMS key."
  type        = map(string)
  default     = {}
}
