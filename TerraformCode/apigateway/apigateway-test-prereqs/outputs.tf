###############################################################
# Outputs
###############################################################

output "hello_lambda_arn" {
  description = "-> scenarios 1 (HTTP), 2 (WebSocket), 3 (REST), 4 (swagger import): the single shared Lambda's ARN"
  value       = aws_lambda_function.hello.arn
}

output "hello_lambda_invoke_uri" {
  description = "-> examples/08-openapi-import: import.template_vars.lambda_invoke_uri (pre-formatted, ready to paste)"
  value       = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello.arn}/invocations"
}

output "dynamodb_table_name" {
  description = "-> scenario 5 (DynamoDB): used when building the REST AWS-integration's request template"
  value       = aws_dynamodb_table.test_table.name
}

output "dynamodb_uri_for_rest" {
  description = "-> scenario 5: integrations[].config.uri for a REST API's non-proxy AWS integration hitting DynamoDB PutItem"
  value       = "arn:aws:apigateway:${var.aws_region}:dynamodb:action/PutItem"
}

output "apigw_dynamodb_role_arn" {
  description = "-> scenario 5: integrations[].config.credentials_arn"
  value       = aws_iam_role.apigw_dynamodb.arn
}

output "alb_dns_name" {
  description = "-> scenario 5 (ALB/EC2): integrations[].config.url -- plain HTTP passthrough, e.g. http://<this>/  -- no VPC Link needed"
  value       = "http://${aws_lb.test_alb.dns_name}"
}

output "s3_bucket_name" {
  description = "-> scenario 6 (S3): used when building the REST AWS-integration's request template"
  value       = aws_s3_bucket.uploads.bucket
}

output "s3_uri_for_rest" {
  description = "-> scenario 6: integrations[].config.uri for a REST API's non-proxy AWS integration hitting S3 PutObject"
  value       = "arn:aws:apigateway:${var.aws_region}:s3:path/${aws_s3_bucket.uploads.bucket}/{key}"
}

output "apigw_s3_role_arn" {
  description = "-> scenario 6: integrations[].config.credentials_arn"
  value       = aws_iam_role.apigw_s3.arn
}

output "apigateway_account_settings_managed" {
  description = "Whether this apply configured the account-wide CloudWatch Logs role"
  value       = var.manage_apigateway_account_settings
}
