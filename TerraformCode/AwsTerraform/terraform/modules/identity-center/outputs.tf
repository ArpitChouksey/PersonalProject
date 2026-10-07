output "instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = data.aws_ssoadmin_instances.this.arns[0]
}

output "identity_store_id" {
  description = "IAM Identity Center Identity Store ID"
  value       = var.identity_store_id
}

output "permission_set_arns" {
  description = "Permission set ARNs"
  value = {
    for key, permission_set in aws_ssoadmin_permission_set.this :
    key => permission_set.arn
  }
}

output "user_ids" {
  description = "Identity Center user IDs"
  value = {
    for key, user in aws_identitystore_user.this :
    key => user.user_id
  }
}
