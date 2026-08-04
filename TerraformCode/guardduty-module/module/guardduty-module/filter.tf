resource "aws_guardduty_filter" "this" {
  for_each = { for f in var.filters : f.name => f }

  detector_id = local.detector_id
  name        = each.value.name
  description = each.value.description
  action      = each.value.action
  rank        = each.value.rank

  finding_criteria {
    dynamic "criterion" {
      for_each = each.value.criteria
      content {
        field                 = criterion.value.field
        equals                = length(criterion.value.equals) > 0 ? criterion.value.equals : null
        not_equals            = length(criterion.value.not_equals) > 0 ? criterion.value.not_equals : null
        greater_than          = criterion.value.greater_than != "" ? criterion.value.greater_than : null
        greater_than_or_equal = criterion.value.greater_than_or_equal != "" ? criterion.value.greater_than_or_equal : null
        less_than             = criterion.value.less_than != "" ? criterion.value.less_than : null
        less_than_or_equal    = criterion.value.less_than_or_equal != "" ? criterion.value.less_than_or_equal : null
      }
    }
  }

  tags = var.tags
}
