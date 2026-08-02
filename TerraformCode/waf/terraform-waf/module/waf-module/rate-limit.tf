locals {
  rate_based_rule_entries = [
    for r in var.rate_based_rules : {
      rule_type = "rate"
      name      = r.name
      priority  = r.priority
      action    = r.action
      rate      = r
    }
  ]
}
