##############################################
# Toggle flags - one deployment file, gated blocks
##############################################
variable "enable_documents" {
  description = "Create custom SSM documents"
  type        = bool
  default     = false
}

variable "enable_associations" {
  description = "Create generic SSM associations (State Manager)"
  type        = bool
  default     = false
}

variable "enable_inventory" {
  description = "Enable managed instance inventory collection"
  type        = bool
  default     = false
}

variable "enable_patch_compliance" {
  description = "Create patch baseline, patch group, and maintenance window to run patching"
  type        = bool
  default     = false
}

##############################################
# Shared / naming
##############################################
variable "name_prefix" {
  description = "Prefix applied to all resources created by this module"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

##############################################
# S3 reporting bucket (this module owns it)
##############################################
variable "create_reports_bucket" {
  description = "Create an S3 bucket in this account for association/inventory/patch output. Same-account only - module has no credentials to reach another account."
  type        = bool
  default     = true
}

variable "reports_bucket_name" {
  description = "Name for the reports bucket (only used if create_reports_bucket = true). Must be globally unique."
  type        = string
  default     = null
}

##############################################
# Custom SSM documents
##############################################
variable "documents" {
  description = "Map of custom SSM documents to create. Key is a logical name."
  type = map(object({
    name            = string
    document_type   = string           # Command, Automation, Policy, etc.
    document_format = optional(string, "JSON")
    content         = string           # full document body (JSON or YAML string)
  }))
  default = {}
}

##############################################
# Generic associations (State Manager) - both custom docs and AWS-managed docs
##############################################
variable "associations" {
  description = "Map of SSM associations. document_name can reference a custom document's `name` (created above) or an AWS-managed document (e.g. AWS-RunShellScript)."
  type = map(object({
    name                 = string
    document_name        = string
    document_version     = optional(string, "$DEFAULT")
    schedule_expression  = optional(string)
    compliance_severity  = optional(string, "MEDIUM")
    max_errors           = optional(string, "10%")
    max_concurrency      = optional(string, "50%")
    parameters           = optional(map(string), {}) # AWS-managed docs expect a single string per key - comma-join if a doc param needs multiple values
    # Multiple values per tag key are supported (OR match). Multiple target
    # blocks (different keys) are AND-ed together.
    targets = list(object({
      key    = string
      values = list(string)
    }))
    write_output_to_s3 = optional(bool, true)
  }))
  default = {}
}

##############################################
# Managed instance inventory
##############################################
variable "inventory_targets" {
  description = "Tag-based targets for the inventory association (AWS-GatherSoftwareInventory)."
  type = list(object({
    key    = string
    values = list(string)
  }))
  default = []
}

variable "inventory_schedule_expression" {
  description = "How often to collect inventory"
  type        = string
  default     = "rate(1 day)"
}

##############################################
# Patch compliance - one entry per OS/platform. Key is a logical name
# ("linux", "windows", etc) used in resource names; each entry gets its own
# baseline (or AWS's default), patch group, and maintenance window, since
# patch baselines are always OS-scoped in AWS - one baseline can't cover
# mixed Linux + Windows fleets.
##############################################
variable "patch_configs" {
  description = "Map of per-OS patch configs. Key is a logical name (e.g. \"linux\", \"windows\") - each becomes its own baseline/patch group/maintenance window."
  type = map(object({
    operating_system = string # e.g. AMAZON_LINUX_2, WINDOWS, UBUNTU, REDHAT_ENTERPRISE_LINUX, ...

    create_custom_patch_baseline = optional(bool, false) # false = use AWS's own default baseline for this OS, zero config
    patch_baseline_name           = optional(string)      # only used when create_custom_patch_baseline = true
    patch_approval_rules = optional(list(object({
      approve_after_days = optional(number, 0) # 0 = approved immediately, no waiting period
      compliance_level    = optional(string, "CRITICAL")
      patch_filters = list(object({
        key    = string
        values = list(string)
      }))
    })), [])
    patch_approved_patches = optional(list(string), [])
    patch_rejected_patches = optional(list(string), [])

    patch_group_name = string # value written to the "Patch Group" tag on instances that use this baseline

    # "Scan" = report compliance only, no changes made to instances.
    # "Install" = actually install approved patches (and reports compliance).
    patch_operation = optional(string, "Install")

    # Multiple tag values per key are supported (OR match); a single value in
    # the list is equally valid - this isn't required to be multi-valued.
    patch_targets = list(object({
      key    = string
      values = list(string)
    }))

    # How many targeted instances patch AT ONCE. "1" = strictly one at a
    # time (fully sequential). "50%" = half the fleet in parallel. "100%"
    # (default) = all matched instances patch simultaneously.
    max_concurrency = optional(string, "100%")
    # How many failures are tolerated before SSM stops launching new
    # invocations for this run. "0" = stop on the very first failure.
    max_errors = optional(string, "10%")

    maintenance_window_schedule = optional(string, "cron(0 2 ? * SUN *)")
    maintenance_window_duration = optional(number, 4)
    maintenance_window_cutoff   = optional(number, 1)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.patch_configs : contains(["Scan", "Install"], v.patch_operation)])
    error_message = "patch_operation must be either \"Scan\" (report only, no changes) or \"Install\" (actually patch)."
  }
}

##############################################
# Optional compliance report Lambda
##############################################
variable "enable_reporting_lambda" {
  description = "true = create the compliance/non-compliance CSV report Lambda. false = only the core SSM pieces (documents/associations/inventory/patch) get created."
  type        = bool
  default     = false
}

variable "reports_prefix" {
  description = "S3 key prefix (within the same reports bucket) where the Lambda writes its CSV reports"
  type        = string
  default     = "Reports/"
}

variable "reporting_lambda_schedule_expression" {
  description = "How often the report Lambda runs on a schedule, independent of patch runs"
  type        = string
  default     = "rate(1 day)"
}

variable "reporting_lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "reporting_lambda_timeout" {
  type    = number
  default = 300
}

variable "reporting_lambda_memory" {
  type    = number
  default = 256
}
