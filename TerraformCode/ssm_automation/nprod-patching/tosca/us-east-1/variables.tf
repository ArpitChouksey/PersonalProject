variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "environment_tag_value" {
  description = "Value of the environment tag used to target instances (e.g. nprod)"
  type        = string
}

variable "operating_system" {
  description = "SSM patch baseline operating system family (e.g. AMAZON_LINUX_2, RHEL_9, UBUNTU, WINDOWS)"
  type        = string
}

variable "patch_classifications" {
  description = "Patch classifications to auto-approve"
  type        = list(string)
}

variable "patch_severities" {
  description = "Patch severities to auto-approve"
  type        = list(string)
}

variable "patch_approve_after_days" {
  description = "Days to wait before auto-approving a patch after release"
  type        = number
}

variable "maintenance_window_schedule" {
  description = "Cron expression for the maintenance window"
  type        = string
}

variable "maintenance_window_duration_hours" {
  description = "Duration of the maintenance window in hours"
  type        = number
}

variable "maintenance_window_cutoff_hours" {
  description = "Stop scheduling new tasks this many hours before the window ends"
  type        = number
}

variable "max_concurrency" {
  description = "Max concurrent instances the maintenance window task will target at once"
  type        = string
}

variable "max_errors" {
  description = "Max errors allowed before the maintenance window task stops"
  type        = string
}

variable "operation_mode" {
  description = "Scan or Install - controls whether patching installs or just scans"
  type        = string
}

variable "take_backup" {
  description = "Whether to take an on-demand backup before patching"
  type        = bool
}

variable "parameter_store_prefix" {
  description = "Prefix path for control-flag parameters in SSM Parameter Store"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime for all functions"
  type        = string
}

variable "lambda_timeout_seconds" {
  description = "Timeout in seconds for compliance_check, classify_failure, and report_builder functions"
  type        = number
}

variable "rca_lambda_timeout_seconds" {
  description = "Timeout in seconds for the rca_collector function"
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
}

variable "map_max_concurrency" {
  description = "Max concurrent instances processed by the Step Functions Map state"
  type        = number
}

variable "transient_retry_max_attempts" {
  description = "Max bounded business-level retries for transient patch failures"
  type        = number
}

variable "test_schedule_expression" {
  description = "EventBridge schedule expression used during testing phase (e.g. rate(1 hour))"
  type        = string
}

variable "enable_test_schedule" {
  description = "Whether the hourly test-schedule EventBridge rule is active"
  type        = bool
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}
