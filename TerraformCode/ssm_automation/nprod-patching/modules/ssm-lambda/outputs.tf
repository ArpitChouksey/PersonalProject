output "ses_identities_pending_verification" {
  description = "Email addresses registered with SES - check console or run 'aws ses get-identity-verification-attributes' to confirm each shows Verified after clicking the link AWS emails to it"
  value       = keys(aws_ses_email_identity.verified_emails)
}

output "patching_dispatcher_function_arn" {
  description = "ARN of the single dispatcher Lambda function handling all 7 tasks"
  value       = aws_lambda_function.patching_dispatcher.arn
}

output "patching_dispatcher_function_name" {
  description = "Name of the dispatcher Lambda function"
  value       = aws_lambda_function.patching_dispatcher.function_name
}

output "report_bucket_name" {
  description = "Name of the S3 bucket used for report/log archival"
  value       = aws_s3_bucket.report_archive.bucket
}

output "restore_approval_topic_arn" {
  description = "ARN of the SNS topic used for restore-approval notifications"
  value       = aws_sns_topic.restore_approval.arn
}
