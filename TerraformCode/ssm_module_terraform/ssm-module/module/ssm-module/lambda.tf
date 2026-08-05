# Optional compliance / non-compliance CSV report Lambda. Fully gated by
# var.enable_reporting_lambda - when false, none of this gets created, only
# the core SSM pieces (documents/associations/inventory/patch) do.

data "archive_file" "reporting_lambda" {
  count       = var.enable_reporting_lambda ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda-src/compliance_report.py"
  output_path = "${path.module}/lambda-src/compliance_report.zip"
}

resource "aws_iam_role" "reporting_lambda_role" {
  count = var.enable_reporting_lambda ? 1 : 0
  name  = "${var.name_prefix}-ssm-compliance-report-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "reporting_lambda_basic_logs" {
  count      = var.enable_reporting_lambda ? 1 : 0
  role       = aws_iam_role.reporting_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "reporting_lambda_permissions" {
  count = var.enable_reporting_lambda ? 1 : 0
  name  = "${var.name_prefix}-ssm-compliance-report-permissions"
  role  = aws_iam_role.reporting_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadComplianceAndInventoryData"
        Effect = "Allow"
        Action = [
          "ssm:ListComplianceItems",
          "ssm:ListResourceComplianceSummaryItems",
          "ssm:DescribeInstanceInformation",
          "ec2:DescribeInstances"
        ]
        Resource = "*" # these are read-only, list-style APIs with no resource-level ARN support
      },
      {
        Sid      = "WriteReportsToOwnBucket"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${local.reports_bucket_arn}/${var.reports_prefix}*"
      }
    ]
  })
}

resource "aws_lambda_function" "reporting" {
  count            = var.enable_reporting_lambda ? 1 : 0
  function_name    = "${var.name_prefix}-ssm-compliance-report"
  role             = aws_iam_role.reporting_lambda_role[0].arn
  handler          = "compliance_report.handler"
  runtime          = var.reporting_lambda_runtime
  timeout          = var.reporting_lambda_timeout
  memory_size      = var.reporting_lambda_memory
  filename         = data.archive_file.reporting_lambda[0].output_path
  source_code_hash = data.archive_file.reporting_lambda[0].output_base64sha256

  environment {
    variables = {
      REPORTS_BUCKET = local.reports_bucket_name
      REPORTS_PREFIX = var.reports_prefix
    }
  }

  tags = var.tags
}

##############################################
# Trigger 1: schedule (e.g. daily)
##############################################
resource "aws_cloudwatch_event_rule" "reporting_schedule" {
  count               = var.enable_reporting_lambda ? 1 : 0
  name                = "${var.name_prefix}-ssm-compliance-report-schedule"
  schedule_expression = var.reporting_lambda_schedule_expression
}

resource "aws_cloudwatch_event_target" "reporting_schedule" {
  count     = var.enable_reporting_lambda ? 1 : 0
  rule      = aws_cloudwatch_event_rule.reporting_schedule[0].name
  target_id = "reporting-lambda-schedule"
  arn       = aws_lambda_function.reporting[0].arn
}

resource "aws_lambda_permission" "allow_schedule" {
  count         = var.enable_reporting_lambda ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgeSchedule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reporting[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.reporting_schedule[0].arn
}

##############################################
# Trigger 2: right after each patch maintenance window run finishes
# (SUCCESS, FAILED, or TIMED_OUT - we want a report even on failure)
# Only wired up when patch compliance is actually enabled, since it needs
# the maintenance window's ID to filter on.
##############################################
resource "aws_cloudwatch_event_rule" "reporting_after_patch_run" {
  count = var.enable_reporting_lambda && var.enable_patch_compliance && length(var.patch_configs) > 0 ? 1 : 0
  name  = "${var.name_prefix}-ssm-compliance-report-after-patch-run"

  event_pattern = jsonencode({
    source      = ["aws.ssm"]
    detail-type = ["Maintenance Window Execution State-change"]
    detail = {
      # One maintenance window per OS now - watch all of them, so the report
      # fires after any OS's patch run finishes, not just one.
      window-id = [for w in aws_ssm_maintenance_window.patching : w.id]
      status    = ["SUCCESS", "FAILED", "TIMED_OUT"]
    }
  })
}

resource "aws_cloudwatch_event_target" "reporting_after_patch_run" {
  count     = var.enable_reporting_lambda && var.enable_patch_compliance && length(var.patch_configs) > 0 ? 1 : 0
  rule      = aws_cloudwatch_event_rule.reporting_after_patch_run[0].name
  target_id = "reporting-lambda-after-patch-run"
  arn       = aws_lambda_function.reporting[0].arn
}

resource "aws_lambda_permission" "allow_after_patch_run" {
  count         = var.enable_reporting_lambda && var.enable_patch_compliance && length(var.patch_configs) > 0 ? 1 : 0
  statement_id  = "AllowExecutionFromPatchRunEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reporting[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.reporting_after_patch_run[0].arn
}
