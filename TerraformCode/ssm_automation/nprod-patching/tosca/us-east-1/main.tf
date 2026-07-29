terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Local state for local testing - state file will be created as
  # terraform.tfstate in this directory. Switch back to the S3 backend
  # block (bucket/key/dynamodb_table) once you move this into your
  # actual environment, so state isn't just sitting on one laptop.
}

provider "aws" {
  region = var.aws_region
}

module "ssm_policy" {
  source = "../../modules/ssm-policy"

  environment_tag_value             = var.environment_tag_value
  operating_system                  = var.operating_system
  patch_classifications             = var.patch_classifications
  patch_severities                  = var.patch_severities
  patch_approve_after_days          = var.patch_approve_after_days
  maintenance_window_schedule       = var.maintenance_window_schedule
  maintenance_window_duration_hours = var.maintenance_window_duration_hours
  maintenance_window_cutoff_hours   = var.maintenance_window_cutoff_hours
  max_concurrency                   = var.max_concurrency
  max_errors                        = var.max_errors
  operation_mode                    = var.operation_mode
  take_backup                       = var.take_backup
  parameter_store_prefix            = var.parameter_store_prefix
  tags                              = var.tags
}

module "ssm_lambda" {
  source = "../../modules/ssm-lambda"

  environment_tag_value                    = var.environment_tag_value
  lambda_runtime                           = var.lambda_runtime
  lambda_timeout_seconds                   = var.lambda_timeout_seconds
  rca_lambda_timeout_seconds               = var.rca_lambda_timeout_seconds
  lambda_memory_size                       = var.lambda_memory_size
  code_source_dir                          = var.code_source_dir
  rca_document_name                        = module.ssm_policy.rca_document_name
  rca_document_arn                         = module.ssm_policy.rca_document_arn
  report_bucket_name                       = var.report_bucket_name
  report_bucket_expiration_days            = var.report_bucket_expiration_days
  report_bucket_noncurrent_expiration_days = var.report_bucket_noncurrent_expiration_days
  ses_sender_email                         = var.ses_sender_email
  report_recipient_emails                  = var.report_recipient_emails
  backup_vault_name                        = var.backup_vault_name
  backup_service_role_arn                  = var.backup_service_role_arn
  approval_notification_emails             = var.approval_notification_emails
  reboot_option                            = var.reboot_option
  tags                                     = var.tags
}

module "ssm_stepfunctions" {
  source = "../../modules/ssm-stepfunctions"

  environment_tag_value            = var.environment_tag_value
  patching_dispatcher_function_arn = module.ssm_lambda.patching_dispatcher_function_arn
  map_max_concurrency              = var.map_max_concurrency
  transient_retry_max_attempts     = var.transient_retry_max_attempts
  operation_mode_parameter_name    = module.ssm_policy.operation_mode_parameter_name
  take_backup_parameter_name       = module.ssm_policy.take_backup_parameter_name
  parameter_store_prefix           = var.parameter_store_prefix
  test_schedule_expression         = var.test_schedule_expression
  enable_test_schedule             = var.enable_test_schedule
  production_schedule_expression   = var.maintenance_window_schedule
  tags                             = var.tags
}
