output "reports_bucket_name" {
  value = module.ssm.reports_bucket_name
}

output "ssm_instance_profile_name" {
  value = module.ssm.ssm_instance_profile_name
}

output "document_names" {
  value = module.ssm.document_names
}

output "association_ids" {
  value = module.ssm.association_ids
}

output "patch_baseline_ids" {
  value = module.ssm.patch_baseline_ids
}

output "custom_patch_baseline_keys" {
  value = module.ssm.custom_patch_baseline_keys
}

output "patch_groups" {
  value = module.ssm.patch_groups
}

output "maintenance_window_ids" {
  value = module.ssm.maintenance_window_ids
}

output "reporting_lambda_function_name" {
  value = module.ssm.reporting_lambda_function_name
}

output "reports_csv_prefix" {
  value = module.ssm.reports_csv_prefix
}
