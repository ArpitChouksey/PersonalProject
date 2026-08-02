resource "aws_wafv2_ip_set" "this" {
  for_each = { for s in var.ip_sets : s.name => s }

  name               = "${local.resource_name}-${each.value.name}"
  description        = "IP set '${each.value.name}' for ${local.resource_name}"
  scope              = var.scope
  ip_address_version = each.value.ip_address_version
  addresses          = each.value.addresses

  tags = var.tags
}

locals {
  ip_set_rule_entries = [
    for s in var.ip_sets : {
      rule_type = "ip_set"
      name      = s.name
      priority  = s.priority
      action    = s.action
      ip_set_arn = aws_wafv2_ip_set.this[s.name].arn
    }
  ]
}
