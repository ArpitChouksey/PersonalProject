##############################################
# ROOT MODULE (this deployment)
#
# Loads the SHARED WAF policy YAML (identical across all dev deployments)
# and layers this deployment's own scope/resource_arns/log destination on
# top, then calls the CHILD module directly at ../../../module/waf-module.
##############################################

locals {
  waf_config = yamldecode(file("${path.module}/../../../config/wafconfig/webacls/${var.webacl_config_file}"))
}

module "waf" {
  source = "../../../module/waf-module"

  name           = local.waf_config.name
  name_prefix    = try(local.waf_config.name_prefix, "")
  description    = try(local.waf_config.description, "Managed WAFv2 Web ACL")
  default_action = try(local.waf_config.default_action, "allow")
  tags           = try(local.waf_config.tags, {})

  cloudwatch_metrics_enabled = try(local.waf_config.cloudwatch_metrics_enabled, true)
  sampled_requests_enabled   = try(local.waf_config.sampled_requests_enabled, true)

  managed_rule_groups = try(local.waf_config.managed_rule_groups, [])
  rate_based_rules    = try(local.waf_config.rate_based_rules, [])
  ip_sets             = try(local.waf_config.ip_sets, [])
  geo_match_rules      = try(local.waf_config.geo_match_rules, [])
  regex_pattern_rules  = try(local.waf_config.regex_pattern_rules, [])
  custom_rules         = try(local.waf_config.custom_rules, [])

  # Deployment-specific (region/scope) - NOT in the shared YAML
  scope                   = var.scope
  resource_arns           = var.resource_arns
  log_destination_configs = var.log_destination_configs

  enable_logging  = try(local.waf_config.enable_logging, false)
  redacted_fields = try(local.waf_config.redacted_fields, [])
}
