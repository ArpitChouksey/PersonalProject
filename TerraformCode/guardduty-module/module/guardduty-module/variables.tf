##############################################
# DETECTOR
##############################################

variable "enable" {
  description = "Whether the GuardDuty detector is enabled."
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = "How often GuardDuty publishes updates to findings. One of FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  type        = string
  default     = "SIX_HOURS"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency must be one of FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}

variable "tags" {
  description = "Tags applied to the detector and any resources this module creates."
  type        = map(string)
  default     = {}
}

##############################################
# OPTIONAL FEATURES (S3 protection, EKS protection, Malware Protection, etc.)
##############################################

variable "features" {
  description = <<-EOT
    List of GuardDuty detector features to enable/disable. Each object:
      name                    - e.g. "S3_DATA_EVENTS", "EKS_AUDIT_LOGS", "EBS_MALWARE_PROTECTION",
                                 "RDS_LOGIN_EVENTS", "LAMBDA_NETWORK_LOGS", "EKS_RUNTIME_MONITORING",
                                 "RUNTIME_MONITORING" (see AWS docs for the full, evolving list)
      status                  - "ENABLED" or "DISABLED"
      additional_configuration - optional list of { name, status } sub-features
                                 (e.g. EKS_RUNTIME_MONITORING has an "EKS_ADDON_MANAGEMENT" sub-feature)
  EOT
  type = list(object({
    name   = string
    status = string
    additional_configuration = optional(list(object({
      name   = string
      status = string
    })), [])
  }))
  default = []

  validation {
    condition     = alltrue([for f in var.features : contains(["ENABLED", "DISABLED"], f.status)])
    error_message = "status for each feature must be ENABLED or DISABLED."
  }
}

##############################################
# IP SETS (trusted IPs GuardDuty should never alert on)
##############################################

variable "ip_sets" {
  description = <<-EOT
    List of trusted IP sets. Each object:
      name     - unique name
      format   - "TXT" | "STIX" | "OTX_CSV" | "ALIEN_VAULT" | "PROOF_POINT" | "FIRE_EYE"
      location - S3 URI or HTTPS URL to the list file
      activate - whether GuardDuty should treat these as trusted immediately
  EOT
  type = list(object({
    name     = string
    format   = string
    location = string
    activate = bool
  }))
  default = []
}

##############################################
# THREAT INTEL SETS (known-bad IPs to always alert on)
##############################################

variable "threat_intel_sets" {
  description = "Same shape as ip_sets, but for known-malicious IPs GuardDuty should always flag."
  type = list(object({
    name     = string
    format   = string
    location = string
    activate = bool
  }))
  default = []
}

##############################################
# FILTERS (suppress or auto-archive noisy/expected findings)
##############################################

variable "filters" {
  description = <<-EOT
    List of finding filters. Each object:
      name        - unique name
      description - optional description
      action      - "ARCHIVE" (auto-archive matching findings) or "NOOP" (match only, no action)
      rank        - evaluation order, lower runs first, must be unique across all filters
      criteria    - list of { field, equals, not_equals, greater_than, greater_than_or_equal,
                     less_than, less_than_or_equal } - set only the comparison(s) that apply
                     per condition; leave the rest at their defaults ([] or "")
  EOT
  type = list(object({
    name        = string
    description = optional(string, "")
    action      = string
    rank        = number
    criteria = list(object({
      field                 = string
      equals                = optional(list(string), [])
      not_equals            = optional(list(string), [])
      greater_than          = optional(string, "")
      greater_than_or_equal = optional(string, "")
      less_than             = optional(string, "")
      less_than_or_equal    = optional(string, "")
    }))
  }))
  default = []

  validation {
    condition     = alltrue([for f in var.filters : contains(["ARCHIVE", "NOOP"], f.action)])
    error_message = "action for each filter must be ARCHIVE or NOOP."
  }
}

##############################################
# PUBLISHING DESTINATION (export findings to S3)
##############################################

variable "enable_publishing" {
  description = "Whether to publish findings to an S3 bucket via a publishing destination."
  type        = bool
  default     = false
}

variable "publishing_destination_arn" {
  description = "ARN of the S3 bucket to publish findings to. Required when enable_publishing = true."
  type        = string
  default     = ""
}

variable "publishing_kms_key_arn" {
  description = "KMS key ARN used to encrypt published findings. Required when enable_publishing = true (GuardDuty requires SSE-KMS specifically on the destination bucket)."
  type        = string
  default     = ""
}

variable "create_publishing_bucket" {
  description = <<-EOT
    Whether this module creates its OWN findings bucket, in the SAME
    account as the detector - the AWS-recommended pattern, since it avoids
    any cross-account bucket policy entirely.

    When true: publishing_destination_arn is ignored - the self-created
    bucket's ARN is used automatically. Set publishing_bucket_name and
    publishing_kms_key_arn (required either way).

    When false (default): publishing_destination_arn must point at an
    existing bucket - either one already in this account, or one owned by
    a different account (in which case see the external_bucket_policy_json
    output - that account's owner must apply it themselves; this module
    cannot reach into another account).
  EOT
  type    = bool
  default = false
}

variable "publishing_bucket_name" {
  description = "Name for the self-created findings bucket. Required when create_publishing_bucket = true (must be globally unique, like any S3 bucket name)."
  type        = string
  default     = ""
}

##############################################
# SINGLE-ACCOUNT vs MULTI-ACCOUNT (AWS Organizations)
#
# Everything above works identically for both - a plain single-account
# detector never touches any of the variables below (they all default to
# off). Multi-account support is opt-in via the three variables here.
##############################################

variable "create_detector" {
  description = <<-EOT
    Whether this deployment creates its own GuardDuty detector. Leave this
    at the default (true) for every normal case, including a delegated
    admin account (which needs its own detector).

    Set to false ONLY for a management-account-only deployment whose sole
    purpose is designating a delegated admin via
    enable_organization_admin - that action doesn't require a detector in
    the management account itself.
  EOT
  type    = bool
  default = true
}

variable "enable_organization_admin" {
  description = <<-EOT
    Whether to designate a delegated administrator account for GuardDuty
    across an AWS Organization.

    IMPORTANT: AWS only allows the ORGANIZATION MANAGEMENT ACCOUNT to call
    this action. Only ever apply this variable's deployment using
    management-account credentials - applying it from any other account
    will fail at the AWS API level.
  EOT
  type    = bool
  default = false
}

variable "delegated_admin_account_id" {
  description = "AWS account ID to designate as the GuardDuty delegated administrator. Required when enable_organization_admin = true."
  type        = string
  default     = ""
}

variable "is_organization_admin" {
  description = <<-EOT
    Whether THIS deployment's own detector is the delegated admin detector,
    enabling organization-wide settings (auto_enable_organization_members,
    organization_features, member_accounts below).

    Apply this from the DELEGATED ADMIN ACCOUNT ITSELF - after
    enable_organization_admin has already been applied once from the
    management account to designate this account as admin. Requires
    create_detector = true (the delegated admin needs its own detector).
  EOT
  type    = bool
  default = false
}

variable "auto_enable_organization_members" {
  description = <<-EOT
    Auto-enrollment behavior for member accounts, only used when
    is_organization_admin = true:
      ALL  - auto-enable GuardDuty for every existing AND future org member
      NEW  - auto-enable only for accounts that join the org after this is set
      NONE - no auto-enrollment; enroll accounts explicitly via member_accounts
  EOT
  type    = string
  default = "NEW"

  validation {
    condition     = contains(["ALL", "NEW", "NONE"], var.auto_enable_organization_members)
    error_message = "auto_enable_organization_members must be ALL, NEW, or NONE."
  }
}

variable "organization_features" {
  description = <<-EOT
    Org-wide feature auto-enablement for member accounts, only used when
    is_organization_admin = true. Same feature names as var.features, but
    auto_enable takes ALL|NEW|NONE instead of ENABLED|DISABLED (it controls
    enrollment behavior for member accounts, not a single account's own
    on/off state). Each object:
      name                     - e.g. "S3_DATA_EVENTS", "EKS_RUNTIME_MONITORING"
      auto_enable              - "ALL" | "NEW" | "NONE"
      additional_configuration - optional list of { name, auto_enable } sub-features
  EOT
  type = list(object({
    name        = string
    auto_enable = string
    additional_configuration = optional(list(object({
      name        = string
      auto_enable = string
    })), [])
  }))
  default = []
}

variable "member_accounts" {
  description = <<-EOT
    List of member accounts to explicitly associate with this delegated
    admin's detector, only used when is_organization_admin = true. Needed
    when auto_enable_organization_members = NONE, or to add accounts
    outside the AWS Organization (invited rather than auto-enrolled). Each:
      account_id - the 12-digit AWS account ID
      email      - the account's root/contact email (required by the invite API)
  EOT
  type = list(object({
    account_id = string
    email      = string
  }))
  default = []
}
