## ---------------------------------------------------------------------------
## S3 archive bucket
## ---------------------------------------------------------------------------
resource "aws_s3_bucket" "report_archive" {
  bucket = var.report_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "report_archive_versioning" {
  bucket = aws_s3_bucket.report_archive.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "report_archive_lifecycle" {
  bucket = aws_s3_bucket.report_archive.id

  rule {
    id     = "expire-old-reports"
    status = "Enabled"

    filter {}

    expiration {
      days = var.report_bucket_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.report_bucket_noncurrent_expiration_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "report_archive_block" {
  bucket                  = aws_s3_bucket.report_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## ---------------------------------------------------------------------------
## SNS topic for restore-approval notifications
## ---------------------------------------------------------------------------
resource "aws_sns_topic" "restore_approval" {
  name = "${var.environment_tag_value}-patching-restore-approval"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "restore_approval_emails" {
  for_each  = toset(var.approval_notification_emails)
  topic_arn = aws_sns_topic.restore_approval.arn
  protocol  = "email"
  endpoint  = each.value
}

## ---------------------------------------------------------------------------
## SES email identities - creates identities via Terraform for the sender
## AND every recipient (SES sandbox mode requires every recipient verified
## too, not just the sender). Deduplicated since sender and a recipient can
## be the same address - creating two Terraform resources for one identical
## AWS identity would conflict. AWS still emails a verification link to
## each address that a human must click - that step can't be automated.
## ---------------------------------------------------------------------------
locals {
  ses_identities_to_verify = toset(concat([var.ses_sender_email], var.report_recipient_emails))
}

resource "aws_ses_email_identity" "verified_emails" {
  for_each = local.ses_identities_to_verify
  email    = each.value
}

## ---------------------------------------------------------------------------
## Single dispatcher Lambda - handles all 7 tasks, dispatched by event["task"]
## ---------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "patching_dispatcher_role" {
  name               = "${var.environment_tag_value}-patching-dispatcher-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

# Union of every permission previously scoped to the 7 separate roles.
# NOTE: this is a broader blast radius than the per-function roles - any
# code path in this single function can use any of these permissions,
# not just the one relevant to the task it was invoked for.
resource "aws_iam_role_policy" "patching_dispatcher_policy" {
  name = "patching-dispatcher-policy"
  role = aws_iam_role.patching_dispatcher_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstancePatchStates",
          "ssm:DescribeInstancePatchStatesForPatchGroup",
          "ssm:DescribeInstancePatches",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.report_archive.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.restore_approval.arn
      },
      {
        Effect   = "Allow"
        Action   = ["backup:StartBackupJob", "backup:DescribeBackupJob", "backup:StartRestoreJob", "backup:DescribeRestoreJob"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = var.backup_service_role_arn
        Condition = {
          StringEquals = { "iam:PassedToService" = "backup.amazonaws.com" }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "patching_dispatcher_zip" {
  type        = "zip"
  source_dir  = "${var.code_source_dir}/patching_dispatcher"
  output_path = "${path.module}/build/patching_dispatcher.zip"
}

resource "aws_lambda_function" "patching_dispatcher" {
  function_name    = "${var.environment_tag_value}-patching-dispatcher"
  role             = aws_iam_role.patching_dispatcher_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.rca_lambda_timeout_seconds
  memory_size      = var.lambda_memory_size
  filename         = data.archive_file.patching_dispatcher_zip.output_path
  source_code_hash = data.archive_file.patching_dispatcher_zip.output_base64sha256
  tags             = var.tags

  environment {
    variables = {
      ENVIRONMENT_TAG_VALUE = var.environment_tag_value
      RCA_DOCUMENT_NAME     = var.rca_document_name
      REPORT_BUCKET         = aws_s3_bucket.report_archive.bucket
      BACKUP_VAULT_NAME     = var.backup_vault_name
      BACKUP_IAM_ROLE_ARN   = var.backup_service_role_arn
      APPROVAL_TOPIC_ARN    = aws_sns_topic.restore_approval.arn
      SENDER_EMAIL          = var.ses_sender_email
      RECIPIENT_EMAILS      = join(",", var.report_recipient_emails)
      REBOOT_OPTION         = var.reboot_option
    }
  }
}

## ---------------------------------------------------------------------------
## CloudWatch alarm - single function now, one alarm covers all 7 task paths
## ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "dispatcher_errors" {
  alarm_name          = "${var.environment_tag_value}-patching-dispatcher-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggers on any error from the patching dispatcher Lambda (any of the 7 tasks)"
  tags                = var.tags

  dimensions = {
    FunctionName = aws_lambda_function.patching_dispatcher.function_name
  }
}
