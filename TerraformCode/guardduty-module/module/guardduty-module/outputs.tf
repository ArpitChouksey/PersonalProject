output "detector_id" {
  description = "ID of the GuardDuty detector. Empty string if create_detector = false."
  value       = local.detector_id
}

output "detector_arn" {
  description = "ARN of the GuardDuty detector. Empty string if create_detector = false."
  value       = length(aws_guardduty_detector.this) > 0 ? aws_guardduty_detector.this[0].arn : ""
}

output "ip_set_ids" {
  description = "Map of IP set name to its ID."
  value       = { for k, v in aws_guardduty_ipset.this : k => v.id }
}

output "threat_intel_set_ids" {
  description = "Map of threat intel set name to its ID."
  value       = { for k, v in aws_guardduty_threatintelset.this : k => v.id }
}

output "filter_ids" {
  description = "Map of filter name to its ID."
  value       = { for k, v in aws_guardduty_filter.this : k => v.id }
}

output "organization_admin_designated" {
  description = "Whether this deployment designated a delegated admin account (enable_organization_admin)."
  value       = var.enable_organization_admin
}

output "member_account_ids" {
  description = "Map of member account ID to its GuardDuty member association ID (delegated admin deployments only)."
  value       = { for k, v in aws_guardduty_member.this : k => v.id }
}

output "publishing_bucket_arn" {
  description = "ARN of the self-created findings bucket, when create_publishing_bucket = true. Null otherwise."
  value       = length(aws_s3_bucket.findings) > 0 ? aws_s3_bucket.findings[0].arn : null
}

output "publishing_bucket_name" {
  description = "Name of the self-created findings bucket, when create_publishing_bucket = true. Null otherwise."
  value       = length(aws_s3_bucket.findings) > 0 ? aws_s3_bucket.findings[0].id : null
}

output "external_bucket_policy_json" {
  description = <<-EOT
    Ready-to-apply bucket policy JSON for the CROSS-ACCOUNT case: when
    publishing_destination_arn points at a bucket owned by a DIFFERENT
    account than this detector. This module cannot apply the policy there
    itself (it has no credentials for that account) - copy this output and
    hand it to whoever manages that bucket's Terraform/console.

    Only populated when enable_publishing = true, create_publishing_bucket
    = false, and publishing_destination_arn is set (i.e. the true
    cross-account scenario). Null otherwise - including the normal case
    where create_publishing_bucket = true, since that policy is already
    applied automatically in this same account.
  EOT
  value = (
    var.enable_publishing && !var.create_publishing_bucket && var.publishing_destination_arn != ""
    ? jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "AllowGuardDutyPutObject"
            Effect    = "Allow"
            Principal = { Service = "guardduty.amazonaws.com" }
            Action    = "s3:PutObject"
            Resource  = "${var.publishing_destination_arn}/*"
            Condition = {
              StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
              ArnLike      = { "aws:SourceArn" = "arn:aws:guardduty:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:detector/*" }
            }
          },
          {
            Sid       = "AllowGuardDutyGetBucketLocation"
            Effect    = "Allow"
            Principal = { Service = "guardduty.amazonaws.com" }
            Action    = "s3:GetBucketLocation"
            Resource  = var.publishing_destination_arn
            Condition = {
              StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
            }
          }
        ]
      })
    : null
  )
}
