output "instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = module.identity_center.instance_arn
}

output "identity_store_id" {
  description = "IAM Identity Center Identity Store ID"
  value       = module.identity_center.identity_store_id
}

output "permission_set_arns" {
  description = "IAM Identity Center permission set ARNs"
  value       = module.identity_center.permission_set_arns
}

output "user_ids" {
  description = "IAM Identity Center user IDs"
  value       = module.identity_center.user_ids
}
