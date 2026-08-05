output "reports_bucket_name" {
  value = local.reports_bucket_name
}

output "reports_bucket_arn" {
  value = local.reports_bucket_arn
}

output "ssm_role_arn" {
  value = aws_iam_role.ssm_role.arn
}

output "ssm_instance_profile_name" {
  value = aws_iam_instance_profile.ssm_profile.name
}

output "document_names" {
  value = { for k, v in aws_ssm_document.this : k => v.name }
}

output "association_ids" {
  value = { for k, v in aws_ssm_association.this : k => v.association_id }
}

output "inventory_association_id" {
  value = length(aws_ssm_association.inventory) > 0 ? aws_ssm_association.inventory[0].association_id : null
}

output "patch_baseline_ids" {
  value = local.patch_baseline_ids
}

output "custom_patch_baseline_keys" {
  description = "Which patch_configs keys are using a custom baseline vs AWS's default"
  value       = keys(local.custom_patch_configs)
}

output "maintenance_window_ids" {
  value = { for k, v in aws_ssm_maintenance_window.patching : k => v.id }
}

output "patch_groups" {
  value = { for k, v in aws_ssm_patch_group.this : k => v.patch_group }
}

output "reporting_lambda_function_name" {
  value = length(aws_lambda_function.reporting) > 0 ? aws_lambda_function.reporting[0].function_name : null
}

output "reporting_lambda_arn" {
  value = length(aws_lambda_function.reporting) > 0 ? aws_lambda_function.reporting[0].arn : null
}

output "reports_csv_prefix" {
  value = "${local.reports_bucket_name}/${var.reports_prefix}"
}
