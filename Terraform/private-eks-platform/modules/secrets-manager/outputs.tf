output "secret_id" {
  description = "ID of the Secrets Manager secret."
  value       = aws_secretsmanager_secret.this.id
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret."
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret."
  value       = aws_secretsmanager_secret.this.name
}

output "kms_key_id" {
  description = "KMS key used to encrypt the secret."
  value       = aws_secretsmanager_secret.this.kms_key_id
}
