locals {
  # Use the self-created bucket's ARN when create_publishing_bucket = true,
  # otherwise fall back to whatever ARN was passed in directly (an
  # existing bucket in this account, or one in another account whose owner
  # has already applied the policy from the external_bucket_policy_json
  # output).
  #
  # IMPORTANT: guard with length(...) > 0, not var.create_publishing_bucket
  # directly - aws_s3_bucket.findings[0] is only a valid reference when the
  # resource actually has an instance; indexing into it while its count is
  # 0 raises "Invalid index" even if a boolean var happens to line up with
  # that count elsewhere.
  effective_publishing_destination_arn = length(aws_s3_bucket.findings) > 0 ? aws_s3_bucket.findings[0].arn : var.publishing_destination_arn
}

resource "aws_guardduty_publishing_destination" "this" {
  count = var.enable_publishing ? 1 : 0

  detector_id     = local.detector_id
  destination_arn = local.effective_publishing_destination_arn
  kms_key_arn     = var.publishing_kms_key_arn

  lifecycle {
    precondition {
      # AWS requires SSE-KMS specifically on the destination bucket -
      # kms_key_arn is not truly optional whenever publishing is enabled,
      # regardless of whether the bucket was self-created here or passed
      # in externally. Fail here with a clear message instead of letting
      # AWS's own API error surface later in the apply.
      condition     = var.publishing_kms_key_arn != ""
      error_message = "publishing_kms_key_arn is required whenever enable_publishing = true - GuardDuty requires the destination bucket to use SSE-KMS."
    }
  }
}
