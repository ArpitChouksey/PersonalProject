variable "aws_region" {
  description = "AWS region for this deployment."
  type        = string
}

variable "default_tags" {
  description = "Provider-level default tags applied to every resource in this deployment."
  type        = map(string)
  default     = {}
}

##############################################
# Toggle exactly ONE role to true per apply, matching whichever AWS
# account your current credentials point at. See main.tf's header comment.
##############################################

variable "enable_single_account" {
  description = "Deploy a plain single-account detector - used for dev, prod, staging, or any other individual account. Which policy it loads is set by single_account_config_file below."
  type        = bool
  default     = false
}

variable "single_account_config_file" {
  description = "Filename (relative to ../../config/guarddutyconfig/detectors/) for this account's policy - e.g. \"dev.yaml\" or \"prod.yaml\". Only used when enable_single_account = true. To onboard a new account: create its YAML file, then set this to that filename - no .tf changes needed."
  type        = string
  default     = "dev.yaml"
}

variable "enable_org_management" {
  description = "One-time bootstrap: designate the delegated admin account for AWS Organizations (org-management.yaml). Only needed if you're setting up centralized multi-account findings (see enable_audit_account). Apply with the ORGANIZATION MANAGEMENT ACCOUNT's own credentials."
  type        = bool
  default     = false
}

variable "enable_audit_account" {
  description = "Deploy the audit account's own detector + org-wide settings that pull every member account's findings into this one account (audit-account.yaml). Apply with the AUDIT ACCOUNT's own credentials, after enable_org_management has been applied once."
  type        = bool
  default     = false
}

##############################################
# Shared across whichever role is active (region-specific, not in YAML)
##############################################

variable "enable_publishing" {
  description = "Whether to publish findings to S3."
  type        = bool
  default     = false
}

variable "publishing_destination_arn" {
  description = "S3 bucket ARN for published findings, region-specific."
  type        = string
  default     = ""
}

variable "publishing_kms_key_arn" {
  description = "KMS key ARN to encrypt published findings, region-specific."
  type        = string
  default     = ""
}

variable "create_publishing_bucket" {
  description = "Whether to have the module create its own findings bucket in this same account (recommended - avoids cross-account bucket policies). See guardduty-module's variable of the same name for details."
  type        = bool
  default     = false
}

variable "publishing_bucket_name" {
  description = "Name for the self-created findings bucket. Required when create_publishing_bucket = true."
  type        = string
  default     = ""
}
