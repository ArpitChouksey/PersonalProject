locals {
  managed_rule_entries = [
    for r in var.managed_rule_groups : {
      rule_type       = "managed"
      name            = r.name
      priority        = r.priority
      override_action = r.override_action
      managed         = r
    }
  ]
}
