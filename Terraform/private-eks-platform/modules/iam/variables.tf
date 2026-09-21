variable "secret_reader_role_name" {
  description = "IAM role name used by EKS Pod Identity for reading application secrets."
  type        = string
}

variable "secret_reader_role_description" {
  description = "Description of the IAM role."
  type        = string
}

variable "secret_reader_policy_name" {
  description = "Name of the inline IAM policy."
  type        = string
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the secret."
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
