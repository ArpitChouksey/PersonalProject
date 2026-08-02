##############################################
# CUSTOM RULES
#
# Each entry below is a single-statement rule (byte_match, size_constraint,
# sqli_match, or xss_match). web-acl.tf renders the matching statement block
# based on `statement_type`.
#
# EXTENDING FOR AND / OR / NOT (compound statements):
# AWS WAFv2 supports nesting statements inside and_statement / or_statement /
# not_statement blocks. To add compound rules, introduce a new variable
# (e.g. `compound_rules`) whose objects carry a `logical_operator` field
# ("AND"|"OR"|"NOT") and a `conditions` list of leaf statements using the
# same shape as `custom_rules` below, then add a dynamic "rule" block in
# web-acl.tf that wraps a dynamic "statement" per condition inside the
# corresponding and_statement/or_statement/not_statement block. Kept out of
# this module for now to avoid unused complexity until a real use case needs it.
##############################################

locals {
  custom_rule_entries = [
    for r in var.custom_rules : {
      rule_type = "custom"
      name      = r.name
      priority  = r.priority
      action    = r.action
      custom    = r
    }
  ]
}
