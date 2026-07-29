variable "environment_tag_value" {
  description = "Value of the environment tag used to target instances (e.g. nprod)"
  type        = string
}

variable "operating_system" {
  description = "SSM patch baseline operating system family (e.g. AMAZON_LINUX_2, RHEL_9, UBUNTU, WINDOWS)"
  type        = string
}

variable "patch_classifications" {
  description = "Patch classifications to auto-approve (e.g. Security, Bugfix)"
  type        = list(string)
}

variable "patch_severities" {
  description = "Patch severities to auto-approve (e.g. Critical, Important)"
  type        = list(string)
}

variable "patch_approve_after_days" {
  description = "Days to wait before auto-approving a patch after release"
  type        = number
}

variable "maintenance_window_schedule" {
  description = "Cron expression for the maintenance window (e.g. cron(0 22 ? * SAT *))"
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
  description = "Scan or Install - stored in SSM Parameter Store, controls whether patching installs or just scans"
  type        = string

  validation {
    condition     = contains(["Scan", "Install"], var.operation_mode)
    error_message = "operation_mode must be either 'Scan' or 'Install'."
  }
}

variable "take_backup" {
  description = "Whether to take an on-demand backup before patching (true/false), stored in SSM Parameter Store"
  type        = bool
}

variable "parameter_store_prefix" {
  description = "Prefix path for control-flag parameters in SSM Parameter Store (e.g. /patching/nprod)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources created by this module"
  type        = map(string)
}
