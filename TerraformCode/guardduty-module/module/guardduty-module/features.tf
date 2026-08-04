resource "aws_guardduty_detector_feature" "this" {
  for_each = { for f in var.features : f.name => f }

  detector_id = local.detector_id
  name        = each.value.name
  status      = each.value.status

  dynamic "additional_configuration" {
    for_each = each.value.additional_configuration
    content {
      name   = additional_configuration.value.name
      status = additional_configuration.value.status
    }
  }
}
