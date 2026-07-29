aws_region             = "us-east-1"
environment_tag_value  = "nprod"
operating_system       = "WINDOWS"

patch_classifications    = ["CriticalUpdates", "SecurityUpdates", "UpdateRollups"]
patch_severities          = ["Critical", "Important"]

#patch_classifications    = ["Security", "Bugfix"]
#patch_severities          = ["Critical", "Important"]
patch_approve_after_days  = 0

maintenance_window_schedule       = "cron(0 22 ? * SAT *)"
maintenance_window_duration_hours = 4
maintenance_window_cutoff_hours   = 1

max_concurrency = "10"
max_errors      = "5"

# --- TESTING PHASE VALUES ---
# operation_mode: keep as "Scan" until install permission workflow is fully
# validated end to end, then flip to "Install".
operation_mode = "Scan"

# take_backup: true from day one of Install mode so every real patch run has
# a fresh restore point; revisit turning this off after a stable track record.
take_backup = true

parameter_store_prefix = "/patching/nprod"

lambda_runtime              = "python3.12"
lambda_timeout_seconds      = 120
rca_lambda_timeout_seconds  = 300
lambda_memory_size          = 256

code_source_dir = "../../code"

report_bucket_name                       = "tosca-nprod-patching-reports"
report_bucket_expiration_days             = 90
report_bucket_noncurrent_expiration_days  = 30

ses_sender_email = "arpitchouksey18@gmail.com"

report_recipient_emails = [
  "arpitchouksey18@gmail.com"
]

backup_vault_name = "nprod-backup-vault"

# ARN of the IAM role your existing AWS Backup setup already uses to run
# backup/restore jobs - replace with your real role ARN
backup_service_role_arn = "arn:aws:iam::123456789012:role/service-role/AWSBackupDefaultServiceRole"

approval_notification_emails = [
  "arpitchouksey18@gmail.com"
]

# Windows patches frequently require a reboot to fully apply. This makes
# that decision explicit rather than relying on AWS's silent default.
# NoReboot = patch installs but the instance won't restart automatically;
# you'd need a separate, deliberate reboot step/window afterward.
reboot_option = "RebootIfNeeded"

# Step Functions Map state - how many instances get patched/processed
# concurrently (avoid hammering SSM/Lambda/SES all at once)
map_max_concurrency = 10

# Bounded business-level retries for "transient" classified failures
# (separate from the native Retry block's own 3 attempts on infra errors)
transient_retry_max_attempts = 2

# --- TESTING PHASE: hourly, per your request, until customer-approved cadence ---
test_schedule_expression = "rate(1 hour)"
enable_test_schedule     = true

tags = {
  Environment = "nprod"
  ManagedBy   = "terraform"
  Project     = "automated-patching"
  Owner       = "tosca-cloudops"
}
