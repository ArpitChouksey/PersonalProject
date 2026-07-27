###############################################################
# API Gateway Account Settings -- CloudWatch Logs Role
#
# One-time, account-wide setting -- has nothing to do with any
# specific API. Skip via var.manage_apigateway_account_settings =
# false if this account already has it configured from earlier
# testing.
###############################################################

resource "aws_iam_role" "apigateway_cloudwatch_logs" {

  count = var.manage_apigateway_account_settings ? 1 : 0

  name               = "${var.name_prefix}-apigateway-cloudwatch-logs"
  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json

}

resource "aws_iam_role_policy_attachment" "apigateway_cloudwatch_logs" {

  count = var.manage_apigateway_account_settings ? 1 : 0

  role       = aws_iam_role.apigateway_cloudwatch_logs[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"

}

resource "aws_api_gateway_account" "this" {

  count = var.manage_apigateway_account_settings ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_logs[0].arn

  depends_on = [
    aws_iam_role_policy_attachment.apigateway_cloudwatch_logs
  ]

}
