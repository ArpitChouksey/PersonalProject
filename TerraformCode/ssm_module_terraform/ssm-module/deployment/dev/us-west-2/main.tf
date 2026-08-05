terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Always decode unconditionally - wrapping yamldecode() in a var-flag ternary
# against {} breaks with "Inconsistent conditional result types" since {} and
# the decoded object don't unify. Reading a static file has no side effects,
# so there's no reason to gate it.
locals {
  policy = yamldecode(file("${path.module}/../../../config/ssmconfig/dev/dev.yaml"))

  # Auto-discovers every <os>-custom.yaml in this env's config folder -
  # linux-custom.yaml becomes key "linux", windows-custom.yaml becomes key
  # "windows". Adding a new OS is dropping in a new file, no code change here.
  patch_config_dir   = "${path.module}/../../../config/ssmconfig/dev"
  patch_config_files = fileset(local.patch_config_dir, "*-custom.yaml")
  patch_configs_raw = {
    for f in local.patch_config_files :
    trimsuffix(f, "-custom.yaml") => yamldecode(file("${local.patch_config_dir}/${f}"))
  }

  # var.patch_operations (tfvars) lets you flip an OS between Scan/Install
  # without touching its YAML file - e.g. patch_operations = { linux =
  # "Scan" } for a dry run. Falls back to whatever's in the YAML (default
  # "Install") for any OS not mentioned in tfvars.
  patch_configs = {
    for k, v in local.patch_configs_raw :
    k => merge(v, {
      patch_operation = lookup(var.patch_operations, k, lookup(v, "patch_operation", "Install"))
    })
  }
}

module "ssm" {
  source = "../../../module/ssm-module"

  enable_documents         = local.policy.enable_documents
  enable_associations      = local.policy.enable_associations
  enable_inventory         = local.policy.enable_inventory
  enable_patch_compliance  = local.policy.enable_patch_compliance

  name_prefix = var.name_prefix
  tags        = var.tags

  # account/region-specific - from tfvars, never from the shared YAML
  create_reports_bucket = var.create_reports_bucket
  reports_bucket_name   = var.reports_bucket_name

  documents    = local.policy.documents
  associations = local.policy.associations

  inventory_targets              = local.policy.inventory_targets
  inventory_schedule_expression  = local.policy.inventory_schedule_expression

  patch_configs = local.patch_configs

  enable_reporting_lambda              = var.enable_reporting_lambda
  reports_prefix                       = local.policy.reports_prefix
  reporting_lambda_schedule_expression = local.policy.reporting_lambda_schedule_expression
}
