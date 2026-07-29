## ---------------------------------------------------------------------------
## IAM role for the Step Functions state machine
## ---------------------------------------------------------------------------
resource "aws_iam_role" "state_machine_role" {
  name = "${var.environment_tag_value}-patching-state-machine-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "state_machine_policy" {
  name = "state-machine-policy"
  role = aws_iam_role.state_machine_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = [var.patching_dispatcher_function_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:*:*:parameter${var.parameter_store_prefix}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogDelivery", "logs:GetLogDelivery", "logs:UpdateLogDelivery",
                     "logs:DeleteLogDelivery", "logs:ListLogDeliveries", "logs:PutResourcePolicy",
                     "logs:DescribeResourcePolicies", "logs:DescribeLogGroups"]
        Resource = "*"
      }
    ]
  })
}

## ---------------------------------------------------------------------------
## CloudWatch log group for state machine execution history
## ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "state_machine_logs" {
  name              = "/aws/vendedlogs/states/${var.environment_tag_value}-patching"
  retention_in_days = 90
  tags              = var.tags
}

## ---------------------------------------------------------------------------
## State machine - rendered from the ASL template with Lambda ARNs injected
## ---------------------------------------------------------------------------
resource "aws_sfn_state_machine" "patching_pipeline" {
  name     = "${var.environment_tag_value}-patching-pipeline"
  role_arn = aws_iam_role.state_machine_role.arn
  tags     = var.tags

  definition = templatefile("${path.module}/patching_state_machine.asl.json.tpl", {
    dispatcher_arn                = var.patching_dispatcher_function_arn
    map_max_concurrency           = var.map_max_concurrency
    transient_retry_max_attempts  = var.transient_retry_max_attempts
    operation_mode_parameter_name = var.operation_mode_parameter_name
    take_backup_parameter_name    = var.take_backup_parameter_name
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.state_machine_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

## ---------------------------------------------------------------------------
## IAM role letting EventBridge start executions of the state machine
## ---------------------------------------------------------------------------
resource "aws_iam_role" "eventbridge_start_execution_role" {
  name = "${var.environment_tag_value}-patching-eventbridge-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_start_execution_policy" {
  name = "eventbridge-start-execution-policy"
  role = aws_iam_role.eventbridge_start_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = aws_sfn_state_machine.patching_pipeline.arn
    }]
  })
}

## ---------------------------------------------------------------------------
## EventBridge - hourly test trigger (toggle off via enable_test_schedule
## once production cadence is confirmed). Input matches the state machine's
## expected shape: operation/takeBackup are read from SSM Parameter Store
## by ComplianceCheck's caller at invoke time in your automation glue, or
## hardcode a starting operation/takeBackup pair here per environment.
## ---------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "test_trigger" {
  count               = var.enable_test_schedule ? 1 : 0
  name                = "${var.environment_tag_value}-patching-test-trigger"
  description         = "TEST SCHEDULE - starts the patching pipeline state machine on var.test_schedule_expression during validation."
  schedule_expression = var.test_schedule_expression
  state               = "ENABLED"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "test_trigger_target" {
  count     = var.enable_test_schedule ? 1 : 0
  rule      = aws_cloudwatch_event_rule.test_trigger[0].name
  target_id = "patching-state-machine"
  arn       = aws_sfn_state_machine.patching_pipeline.arn
  role_arn  = aws_iam_role.eventbridge_start_execution_role.arn
  # No input needed - the state machine reads operation/takeBackup live from
  # SSM Parameter Store as its first two states, so flipping those parameter
  # values takes effect on the next trigger with zero changes here.
}

## ---------------------------------------------------------------------------
## EventBridge - production schedule trigger (replaces the previous broad
## "any SSM command finished" rule, which risked re-triggering itself since
## the pipeline's own tasks also call ssm:SendCommand internally). This rule
## starts the whole pipeline directly on the real patch cadence - it is the
## ONLY thing that should kick off a production patch run.
## ---------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "production_schedule" {
  name                = "${var.environment_tag_value}-patching-production-schedule"
  description         = "Starts the patching pipeline state machine on the real production cadence"
  schedule_expression = var.production_schedule_expression
  state               = "ENABLED"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "production_schedule_target" {
  rule      = aws_cloudwatch_event_rule.production_schedule.name
  target_id = "patching-state-machine-production"
  arn       = aws_sfn_state_machine.patching_pipeline.arn
  role_arn  = aws_iam_role.eventbridge_start_execution_role.arn
}
