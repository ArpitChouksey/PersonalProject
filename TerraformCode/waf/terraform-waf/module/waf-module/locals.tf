locals {
  resource_name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  metric_name   = var.metric_name != "" ? var.metric_name : replace(local.resource_name, "-", "")

  # All normalized rule entries are merged here and consumed by the single
  # dynamic "rule" block in web-acl.tf. Each entry carries a `rule_type`
  # discriminator so web-acl.tf knows which statement/action shape to render.
  # Contributed by: managed-rules.tf, rate-limit.tf, ip-set.tf, regex-pattern.tf, custom-rules.tf
  all_rules = concat(
    local.managed_rule_entries,
    local.rate_based_rule_entries,
    local.ip_set_rule_entries,
    local.geo_match_rule_entries,
    local.regex_pattern_rule_entries,
    local.custom_rule_entries,
  )
}
