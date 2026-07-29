output "patch_baseline_id" {
  description = "ID of the created patch baseline"
  value       = aws_ssm_patch_baseline.this.id
}

output "default_patch_baseline_registration_id" {
  description = "Confirms nprod-patch-baseline is registered as the account default for this OS"
  value       = aws_ssm_default_patch_baseline.this.id
}

output "maintenance_window_id" {
  description = "ID of the created maintenance window"
  value       = aws_ssm_maintenance_window.this.id
}

output "rca_document_name" {
  description = "Name of the custom RCA diagnostics SSM document"
  value       = aws_ssm_document.rca_diagnostics.name
}

output "rca_document_arn" {
  description = "ARN of the custom RCA diagnostics SSM document"
  value       = aws_ssm_document.rca_diagnostics.arn
}

output "operation_mode_parameter_name" {
  description = "SSM Parameter Store name holding the operation mode flag"
  value       = aws_ssm_parameter.operation_mode.name
}

output "take_backup_parameter_name" {
  description = "SSM Parameter Store name holding the takeBackup flag"
  value       = aws_ssm_parameter.take_backup.name
}
