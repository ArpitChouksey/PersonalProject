variable "environment_tag_value" {
  description = "Value of the environment tag used to target instances (e.g. nprod)"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime for all functions (e.g. python3.12)"
  type        = string
}

variable "lambda_timeout_seconds" {
  description = "Timeout in seconds for compliance_check, classify_failure, and report_builder functions"
  type        = number
}

variable "rca_lambda_timeout_seconds" {
  description = "Timeout in seconds for the rca_collector function (longer - waits on full diagnostic command)"
  type        = number
}

variable "lambda_memory_size" {
  description = "Memory size (MB) for all Lambda functions"
  type        = number
}

variable "code_source_dir" {
  description = "Path to the root code/ directory containing one subfolder per Lambda function"
  type        = string
}

variable "rca_document_name" {
  description = "Name of the RCA diagnostics SSM document (from ssm-policy module)"
  type        = string
}

variable "rca_document_arn" {
  description = "ARN of the RCA diagnostics SSM document (from ssm-policy module)"
  type        = string
}

variable "report_bucket_name" {
  description = "S3 bucket name for storing raw logs and reports"
  type        = string
}

variable "report_bucket_expiration_days" {
  description = "Number of days after which archived reports/logs expire"
  type        = number
}

variable "report_bucket_noncurrent_expiration_days" {
  description = "Number of days after which noncurrent object versions expire"
  type        = number
}

variable "ses_sender_email" {
  description = "Verified SES sender email address"
  type        = string
}

variable "report_recipient_emails" {
  description = "List of email addresses to receive compliance/patch reports"
  type        = list(string)
}

variable "backup_vault_name" {
  description = "Existing AWS Backup vault name to use for on-demand snapshots"
  type        = string
}

variable "backup_service_role_arn" {
  description = "ARN of the existing IAM role AWS Backup assumes to perform backup/restore jobs"
  type        = string
}

variable "approval_notification_emails" {
  description = "Email addresses subscribed to the restore-approval SNS topic"
  type        = list(string)
}

variable "reboot_option" {
  description = "RebootOption for AWS-RunPatchBaseline: RebootIfNeeded or NoReboot"
  type        = string

  validation {
    condition     = contains(["RebootIfNeeded", "NoReboot"], var.reboot_option)
    error_message = "reboot_option must be either 'RebootIfNeeded' or 'NoReboot'."
  }
}

variable "tags" {
  description = "Tags applied to all resources created by this module"
  type        = map(string)
}
