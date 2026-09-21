variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten."
  type        = string

  default = "MUTABLE"

  validation {
    condition = contains(
      ["MUTABLE", "IMMUTABLE"],
      var.image_tag_mutability
    )

    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable vulnerability scanning when images are pushed."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "ECR encryption type."
  type        = string
  default     = "AES256"

  validation {
    condition = contains(
      ["AES256", "KMS"],
      var.encryption_type
    )

    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the ECR repository."
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Allow repository deletion even when images exist."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the ECR repository."
  type        = map(string)
  default     = {}
}
