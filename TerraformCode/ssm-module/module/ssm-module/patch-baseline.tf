# One of everything below PER OS in var.patch_configs - AWS patch baselines
# are always OS-scoped, so a mixed Linux+Windows fleet needs one baseline
# (or one AWS-default reference), one patch group, and one maintenance
# window per OS. Key = logical name ("linux", "windows", ...).

locals {
  # Only entries that opted into a custom baseline need aws_ssm_patch_baseline.
  custom_patch_configs  = var.enable_patch_compliance ? { for k, v in var.patch_configs : k => v if v.create_custom_patch_baseline } : {}
  default_patch_configs = var.enable_patch_compliance ? { for k, v in var.patch_configs : k => v if !v.create_custom_patch_baseline } : {}
}

resource "aws_ssm_patch_baseline" "this" {
  for_each = local.custom_patch_configs

  name             = each.value.patch_baseline_name
  operating_system = each.value.operating_system
  approved_patches = each.value.patch_approved_patches
  rejected_patches = each.value.patch_rejected_patches

  dynamic "approval_rule" {
    for_each = each.value.patch_approval_rules
    content {
      # approve_after_days = 0 -> approved immediately, no waiting period
      approve_after_days = approval_rule.value.approve_after_days
      compliance_level    = approval_rule.value.compliance_level

      dynamic "patch_filter" {
        for_each = approval_rule.value.patch_filters
        content {
          key    = patch_filter.value.key
          values = patch_filter.value.values
        }
      }
    }
  }

  tags = var.tags
}

# AWS's own predefined baseline for each OS that didn't opt into a custom one.
data "aws_ssm_patch_baseline" "default" {
  for_each = local.default_patch_configs

  owner            = "AWS"
  operating_system = each.value.operating_system
  default_baseline = true
}

locals {
  # Bug pattern we've hit before: guard with a map lookup that can miss,
  # never a bare var.flag ? resource[0].attr : x ternary against something
  # that might have count/for_each = 0 keys.
  patch_baseline_ids = merge(
    { for k, v in aws_ssm_patch_baseline.this : k => v.id },
    { for k, v in data.aws_ssm_patch_baseline.default : k => v.id }
  )
}

# Registers each baseline for a "Patch Group". Instances self-select into a
# group by having a "Patch Group" = <patch_group_name> tag - there is no
# separate targeting resource for this part, the tag IS the mechanism.
resource "aws_ssm_patch_group" "this" {
  for_each    = var.enable_patch_compliance ? var.patch_configs : {}
  baseline_id = local.patch_baseline_ids[each.key]
  patch_group = each.value.patch_group_name
}

# Patch compliance data only appears after a patch operation actually runs.
# One maintenance window per OS - each runs AWS-RunPatchBaseline against only
# that OS's targets and writes output to the reports bucket.
resource "aws_ssm_maintenance_window" "patching" {
  for_each = var.enable_patch_compliance ? var.patch_configs : {}
  name     = "${var.name_prefix}-${each.key}-patch-window"
  schedule = each.value.maintenance_window_schedule
  duration = each.value.maintenance_window_duration
  cutoff   = each.value.maintenance_window_cutoff

  tags = var.tags
}

resource "aws_ssm_maintenance_window_target" "patching" {
  for_each      = var.enable_patch_compliance ? var.patch_configs : {}
  window_id     = aws_ssm_maintenance_window.patching[each.key].id
  resource_type = "INSTANCE"

  dynamic "targets" {
    for_each = each.value.patch_targets
    content {
      key    = targets.value.key
      values = targets.value.values # a single-item list is just as valid as multiple
    }
  }
}

resource "aws_ssm_maintenance_window_task" "patching" {
  for_each         = var.enable_patch_compliance ? var.patch_configs : {}
  window_id        = aws_ssm_maintenance_window.patching[each.key].id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = length(aws_iam_role.mw_task_role) > 0 ? aws_iam_role.mw_task_role[0].arn : null
  max_concurrency  = each.value.max_concurrency
  max_errors       = each.value.max_errors

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patching[each.key].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = [each.value.patch_operation]
      }

      output_s3_bucket     = var.create_reports_bucket ? local.reports_bucket_name : null
      output_s3_key_prefix = "patch-runs/${each.key}/"
    }
  }
}
