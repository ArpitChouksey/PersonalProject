## ---------------------------------------------------------------------------
## Patch Baseline
## ---------------------------------------------------------------------------
resource "aws_ssm_patch_baseline" "this" {
  name             = "${var.environment_tag_value}-patch-baseline"
  description      = "Custom patch baseline for ${var.environment_tag_value}"
  operating_system = var.operating_system

  approval_rule {
    approve_after_days = var.patch_approve_after_days
    compliance_level    = "CRITICAL"

    patch_filter {
      key    = "CLASSIFICATION"
      values = var.patch_classifications
    }

    patch_filter {
      key    = "MSRC_SEVERITY"
      values = var.patch_severities
    }
  }

  approved_patches_compliance_level = "CRITICAL"

  tags = var.tags
}

## ---------------------------------------------------------------------------
## Register this baseline as the account default for this OS. Without this,
## AWS-RunPatchBaseline (whether run manually, by a Maintenance Window, or
## by the pipeline's own patch_instance task) has no way to know to use
## THIS baseline - it would silently fall back to AWS's built-in default
## Windows baseline instead, ignoring your classification/severity rules.
## NOTE: this applies account+OS wide, not just to environment=nprod tagged
## instances - if this account has other Windows instances managed
## separately, they will also start using this baseline.
## ---------------------------------------------------------------------------
resource "aws_ssm_default_patch_baseline" "this" {
  baseline_id      = aws_ssm_patch_baseline.this.id
  operating_system = var.operating_system
}

## ---------------------------------------------------------------------------
## IAM role that lets SSM execute maintenance window tasks
## ---------------------------------------------------------------------------
resource "aws_iam_role" "maintenance_window_role" {
  name = "ssm-${var.environment_tag_value}-maintenance-window-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "maintenance_window_role_attach" {
  role       = aws_iam_role.maintenance_window_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

## ---------------------------------------------------------------------------
## Maintenance Window
## ---------------------------------------------------------------------------
resource "aws_ssm_maintenance_window" "this" {
  name                       = "${var.environment_tag_value}-patch-window"
  schedule                   = var.maintenance_window_schedule
  duration                   = var.maintenance_window_duration_hours
  cutoff                     = var.maintenance_window_cutoff_hours
  allow_unassociated_targets = false

  tags = var.tags
}

resource "aws_ssm_maintenance_window_target" "tag_target" {
  window_id     = aws_ssm_maintenance_window.this.id
  name          = "${var.environment_tag_value}-tag-target"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:environment"
    values = [var.environment_tag_value]
  }
}

## NOTE: no maintenance_window_task here on purpose. The Maintenance
## Window + Target above exist only to reserve the schedule concept in
## SSM; actual patching happens exclusively through the Step Functions
## PatchAttempt state (which has retry/backoff/classification/RCA logic
## this native task never had). Do not add an AWS-RunPatchBaseline task
## here - it would patch instances a second time, redundantly, and could
## re-trigger the pipeline's own event listeners.

## ---------------------------------------------------------------------------
## Control-flag parameters - flip these to change pipeline behavior with zero
## code/Terraform redeploy required for day-to-day operation
## ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "operation_mode" {
  name        = "${var.parameter_store_prefix}/operation"
  description = "Scan or Install - read by Step Functions execution at runtime"
  type        = "String"
  value       = var.operation_mode
  tags        = var.tags
}

resource "aws_ssm_parameter" "take_backup" {
  name        = "${var.parameter_store_prefix}/takeBackup"
  description = "true/false - whether to take an on-demand backup before patching"
  type        = "String"
  value       = tostring(var.take_backup)
  tags        = var.tags
}

## ---------------------------------------------------------------------------
## Custom SSM Document for OS-level diagnostics (RCA collection)
## ---------------------------------------------------------------------------
resource "aws_ssm_document" "rca_diagnostics" {
  name          = "${var.environment_tag_value}-patch-rca-diagnostics"
  document_type = "Command"
  tags          = var.tags

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Collects OS-level diagnostics after a failed patch run (Windows)"
    mainSteps = [
      {
        action = "aws:runPowerShellScript"
        name    = "collectDiagnostics"
        inputs = {
          runCommand = [
            "Write-Output '--- DISK SPACE ---'",
            "Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N='UsedGB';E={[math]::Round(($_.Used/1GB),2)}}, @{N='FreeGB';E={[math]::Round(($_.Free/1GB),2)}}",
            "Write-Output '--- WINDOWS UPDATE HISTORY (last 20) ---'",
            "Get-WmiObject -Class Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 20 HotFixID, Description, InstalledOn | Format-Table -AutoSize",
            "Write-Output '--- SSM AGENT LOG TAIL ---'",
            "Get-Content 'C:\\ProgramData\\Amazon\\SSM\\Logs\\amazon-ssm-agent.log' -Tail 100 -ErrorAction SilentlyContinue",
            "Write-Output '--- PENDING REBOOT CHECK ---'",
            "$pendingReboot = Test-Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Component Based Servicing\\RebootPending'",
            "Write-Output \"Reboot pending: $pendingReboot\"",
            "Write-Output '--- WINDOWS UPDATE SERVICE STATUS ---'",
            "Get-Service -Name wuauserv | Select-Object Status, StartType",
            "Write-Output '--- LAST WINDOWS UPDATE ERROR (if any) ---'",
            "Get-WinEvent -LogName 'System' -MaxEvents 2000 -ErrorAction SilentlyContinue | Where-Object { $_.ProviderName -eq 'Microsoft-Windows-WindowsUpdateClient' -and $_.LevelDisplayName -eq 'Error' } | Select-Object -First 10 TimeCreated, Id, Message | Format-Table -AutoSize -Wrap"
          ]
        }
      }
    ]
  })
}
