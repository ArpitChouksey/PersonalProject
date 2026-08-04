resource "aws_guardduty_threatintelset" "this" {
  for_each = { for s in var.threat_intel_sets : s.name => s }

  detector_id = local.detector_id
  name        = each.value.name
  format      = each.value.format
  location    = each.value.location
  activate    = each.value.activate

  tags = var.tags
}
