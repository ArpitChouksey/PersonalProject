# Bucket that association output, inventory output, and patch-run output
# get written to. Same pattern as guardduty-module's create_publishing_bucket:
# module creates its own bucket in the SAME account. No cross-account reach.

resource "aws_s3_bucket" "reports" {
  count  = var.create_reports_bucket ? 1 : 0
  bucket = var.reports_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "reports" {
  count  = var.create_reports_bucket ? 1 : 0
  bucket = aws_s3_bucket.reports[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  count  = var.create_reports_bucket ? 1 : 0
  bucket = aws_s3_bucket.reports[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reports" {
  count  = var.create_reports_bucket ? 1 : 0
  bucket = aws_s3_bucket.reports[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bug pattern we've hit before (GuardDuty): var.flag ? resource[0].attr : default
# is unsafe once count can be 0. Always guard with length() > 0 instead.
locals {
  reports_bucket_name = length(aws_s3_bucket.reports) > 0 ? aws_s3_bucket.reports[0].id : var.reports_bucket_name
  reports_bucket_arn  = length(aws_s3_bucket.reports) > 0 ? aws_s3_bucket.reports[0].arn : null
}

resource "aws_s3_bucket_policy" "reports" {
  count  = var.create_reports_bucket ? 1 : 0
  bucket = aws_s3_bucket.reports[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "SSMInstanceRoleWrite"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.ssm_role.arn }
        Action    = ["s3:PutObject", "s3:GetBucketLocation"]
        Resource = [
          aws_s3_bucket.reports[0].arn,
          "${aws_s3_bucket.reports[0].arn}/*"
        ]
      },
      {
        Sid       = "SSMServicePrincipalWrite"
        Effect    = "Allow"
        Principal = { Service = "ssm.amazonaws.com" }
        Action    = ["s3:PutObject", "s3:GetBucketLocation"]
        Resource = [
          aws_s3_bucket.reports[0].arn,
          "${aws_s3_bucket.reports[0].arn}/*"
        ]
      }
    ]
  })
}
