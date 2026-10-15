output "role_name" {
  value = aws_iam_role.this.name
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.this.name
}

output "s3_policy_arn" {
  value = aws_iam_policy.s3.arn
}

output "secrets_manager_policy_arn" {
  value = aws_iam_policy.secrets_manager.arn
}
