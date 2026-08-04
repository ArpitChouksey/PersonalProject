##############################################
# ONE FILE, THREE ROLES - toggled by flags in terraform.tfvars.
#
# CRITICAL: these roles run against DIFFERENT AWS ACCOUNTS. Combining the
# files does NOT combine the accounts - switch AWS credentials for the
# account you're targeting, set ONLY that role's flag to true, then apply.
##############################################

locals {
  # Always decode, regardless of which enable_* flag is on - reading a
  # static file has no side effects, and it avoids a Terraform type error:
  # `condition ? yamldecode(...) : {}` fails because {} and the decoded
  # object don't have the same attributes, and Terraform requires both
  # branches of a conditional to unify to one consistent type.
  single_account_config = yamldecode(file("${path.module}/../../config/guarddutyconfig/detectors/${var.single_account_config_file}"))
  org_management_config = yamldecode(file("${path.module}/../../config/guarddutyconfig/detectors/org-management.yaml"))
  audit_account_config  = yamldecode(file("${path.module}/../../config/guarddutyconfig/detectors/audit-account.yaml"))
}

##############################################
# ROLE 1: SINGLE ACCOUNT (dev, prod, staging, or any other account)
#
# This is the role almost everyone uses. Each account gets its own
# detector, fully independent of any organization structure. To onboard a
# NEW account (e.g. prod): create config/guarddutyconfig/detectors/prod.yaml
# (copy dev.yaml as a starting point), then set
# single_account_config_file = "prod.yaml" in that account's
# terraform.tfvars. No .tf code changes needed anywhere - see prod.yaml
# for a worked example.
##############################################

module "guardduty_account" {
  count  = var.enable_single_account ? 1 : 0
  source = "../../module/guardduty-module"

  create_detector               = try(local.single_account_config.create_detector, true)
  enable                        = try(local.single_account_config.enable, true)
  finding_publishing_frequency  = try(local.single_account_config.finding_publishing_frequency, "SIX_HOURS")
  tags                          = try(local.single_account_config.tags, {})

  features          = try(local.single_account_config.features, [])
  ip_sets           = try(local.single_account_config.ip_sets, [])
  threat_intel_sets = try(local.single_account_config.threat_intel_sets, [])
  filters           = try(local.single_account_config.filters, [])

  enable_publishing          = var.enable_publishing
  publishing_destination_arn = var.publishing_destination_arn
  publishing_kms_key_arn     = var.publishing_kms_key_arn
  create_publishing_bucket   = var.create_publishing_bucket
  publishing_bucket_name     = var.publishing_bucket_name
}

##############################################
# ROLE 2: ORG-MANAGEMENT BOOTSTRAP (optional - only if you need
# centralized multi-account findings; see ROLE 3 below)
#
# A ONE-TIME action, not something you keep re-applying. Apply with the
# AWS Organizations MANAGEMENT ACCOUNT's own credentials. If you never need
# ROLE 3 (a single audit account seeing every account's findings), you
# never need this role either - skip both and just use ROLE 1 everywhere.
##############################################

module "guardduty_org_management" {
  count  = var.enable_org_management ? 1 : 0
  source = "../../module/guardduty-module"

  create_detector             = try(local.org_management_config.create_detector, false)
  tags                        = try(local.org_management_config.tags, {})
  enable_organization_admin   = try(local.org_management_config.enable_organization_admin, false)
  delegated_admin_account_id  = try(local.org_management_config.delegated_admin_account_id, "")
}

##############################################
# ROLE 3: AUDIT ACCOUNT (fetches every org member account's findings into
# one place, e.g. for exporting all 100 accounts' findings to one S3
# bucket)
#
# Apply with the AUDIT ACCOUNT's own credentials, AFTER guardduty_org_management
# has been applied once designating this account as admin.
##############################################

module "guardduty_audit_account" {
  count  = var.enable_audit_account ? 1 : 0
  source = "../../module/guardduty-module"

  finding_publishing_frequency = try(local.audit_account_config.finding_publishing_frequency, "SIX_HOURS")
  tags                         = try(local.audit_account_config.tags, {})

  features          = try(local.audit_account_config.features, [])
  ip_sets           = try(local.audit_account_config.ip_sets, [])
  threat_intel_sets = try(local.audit_account_config.threat_intel_sets, [])
  filters           = try(local.audit_account_config.filters, [])

  is_organization_admin            = try(local.audit_account_config.is_organization_admin, false)
  auto_enable_organization_members = try(local.audit_account_config.auto_enable_organization_members, "NEW")
  organization_features            = try(local.audit_account_config.organization_features, [])
  member_accounts                  = try(local.audit_account_config.member_accounts, [])

  # This is the one publishing destination that receives EVERY member
  # account's findings, once they're associated - you do not configure S3
  # export separately per member account.
  enable_publishing          = var.enable_publishing
  publishing_destination_arn = var.publishing_destination_arn
  publishing_kms_key_arn     = var.publishing_kms_key_arn
  create_publishing_bucket   = var.create_publishing_bucket
  publishing_bucket_name     = var.publishing_bucket_name
}
