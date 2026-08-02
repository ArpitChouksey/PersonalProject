resource "aws_wafv2_regex_pattern_set" "this" {
  for_each = { for r in var.regex_pattern_rules : r.name => r }

  name        = "${local.resource_name}-${each.value.name}"
  description = "Regex pattern set '${each.value.name}' for ${local.resource_name}"
  scope       = var.scope

  dynamic "regular_expression" {
    for_each = each.value.regex_strings
    content {
      regex_string = regular_expression.value
    }
  }

  tags = var.tags
}

locals {
  regex_pattern_rule_entries = [
    for r in var.regex_pattern_rules : {
      rule_type              = "regex"
      name                    = r.name
      priority                = r.priority
      action                  = r.action
      regex_pattern_set_arn   = aws_wafv2_regex_pattern_set.this[r.name].arn
      field_to_match_type     = r.field_to_match_type
      header_name             = r.header_name
      text_transformation_type = r.text_transformation_type
    }
  ]
}
