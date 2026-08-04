##############################################
# OPTIONAL: findings bucket, created in THIS SAME ACCOUNT as the detector.
#
# This is the AWS-recommended pattern - the audit account's own bucket,
# no cross-account bucket policy needed at all, because GuardDuty and the
# bucket are already in the same account.
#
# Only used when create_publishing_bucket = true. If you already have a
# bucket (in this account or another), leave this off and set
# publishing_destination_arn directly instead - see the
# external_bucket_policy_json output for the cross-account case.
##############################################

resource "aws_s3_bucket" "findings" {
  count = var.create_publishing_bucket ? 1 : 0

  bucket = var.publishing_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "findings" {
  count = var.create_publishing_bucket ? 1 : 0

  bucket = aws_s3_bucket.findings[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "findings" {
  count = var.create_publishing_bucket ? 1 : 0

  bucket = aws_s3_bucket.findings[0].id

  # GuardDuty specifically requires the publishing destination bucket to
  # use SSE-KMS (not just any encryption) - publishing_kms_key_arn is
  # effectively required whenever create_publishing_bucket = true. See the
  # lifecycle precondition on aws_guardduty_publishing_destination in
  # publishing.tf, which fails fast with a clear message if this is unset.
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.publishing_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "findings" {
  count = var.create_publishing_bucket ? 1 : 0

  bucket = aws_s3_bucket.findings[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "findings" {
  count = var.create_publishing_bucket ? 1 : 0

  bucket = aws_s3_bucket.findings[0].id

  # Inlined directly here (not a separate top-level local) because this
  # resource itself has count = 0 when create_publishing_bucket = false -
  # arguments of a zero-instance resource are never evaluated, so
  # referencing aws_s3_bucket.findings[0] here is always safe. A
  # standalone local referencing the same index would NOT be safe, since
  # locals have no count and get evaluated unconditionally every plan -
  # that was the actual bug here originally (fixed by inlining).
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowGuardDutyPutObject"
        Effect    = "Allow"
        Principal = { Service = "guardduty.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.findings[0].arn}/*"
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
        Resource  = aws_s3_bucket.findings[0].arn
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }
    ]
  })
}
