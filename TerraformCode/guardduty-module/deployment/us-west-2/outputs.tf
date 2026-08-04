##############################################
# Each output is null unless its corresponding enable_* flag was true for
# this apply - only the role you actually deployed will have real values.
#
# Guarded with length(module.x) > 0 rather than var.enable_x directly -
# indexing module.x[0] is only valid when that module block actually has
# an instance; a var-flag ternary alone doesn't reliably prevent Terraform
# from evaluating the invalid index when the module's own count is 0.
##############################################

output "account_detector_id" {
  description = "Detector ID when enable_single_account = true."
  value       = length(module.guardduty_account) > 0 ? module.guardduty_account[0].detector_id : null
}

output "account_filter_ids" {
  value = length(module.guardduty_account) > 0 ? module.guardduty_account[0].filter_ids : null
}

output "org_management_admin_designated" {
  description = "Whether the delegated admin was designated, when enable_org_management = true."
  value       = length(module.guardduty_org_management) > 0 ? module.guardduty_org_management[0].organization_admin_designated : null
}

output "audit_account_detector_id" {
  description = "The audit account's own detector ID, when enable_audit_account = true."
  value       = length(module.guardduty_audit_account) > 0 ? module.guardduty_audit_account[0].detector_id : null
}

output "audit_account_member_account_ids" {
  description = "Map of member account ID -> association ID, when enable_audit_account = true."
  value       = length(module.guardduty_audit_account) > 0 ? module.guardduty_audit_account[0].member_account_ids : null
}

output "audit_account_publishing_bucket_arn" {
  description = "ARN of the self-created findings bucket in the audit account, when enable_audit_account and create_publishing_bucket are both true."
  value       = length(module.guardduty_audit_account) > 0 ? module.guardduty_audit_account[0].publishing_bucket_arn : null
}

output "external_bucket_policy_json" {
  description = "Cross-account bucket policy JSON to hand to another account's bucket owner - populated whenever publishing is enabled with an externally-owned bucket (create_publishing_bucket = false). Check whichever role is active for the actual value."
  value = try(coalesce(
    length(module.guardduty_account) > 0 ? module.guardduty_account[0].external_bucket_policy_json : null,
    length(module.guardduty_audit_account) > 0 ? module.guardduty_audit_account[0].external_bucket_policy_json : null,
  ), null)
}
