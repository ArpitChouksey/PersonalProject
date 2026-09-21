output "secret_reader_role_name" {
  description = "Name of the secret reader IAM role."
  value       = aws_iam_role.secret_reader.name
}

output "secret_reader_role_arn" {
  description = "ARN of the secret reader IAM role."
  value       = aws_iam_role.secret_reader.arn
}

output "secret_reader_role_id" {
  description = "ID of the secret reader IAM role."
  value       = aws_iam_role.secret_reader.id
}
