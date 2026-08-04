##############################################
# DETECTOR (optional - see create_detector)
#
# Most deployments create their own detector (create_detector = true,
# the default). The one exception: a management-account-only deployment
# that JUST designates a delegated admin account
# (var.enable_organization_admin) doesn't need a detector of its own -
# aws_guardduty_organization_admin_account below doesn't require one. Set
# create_detector = false for that case.
##############################################

resource "aws_guardduty_detector" "this" {
  count = var.create_detector ? 1 : 0

  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency

  tags = var.tags
}

locals {
  # Empty string when create_detector = false. Guarded with length(...) > 0
  # rather than var.create_detector directly - indexing
  # aws_guardduty_detector.this[0] is only valid when the resource actually
  # has an instance; a var-flag ternary alone doesn't reliably prevent
  # Terraform from evaluating the invalid index (this exact pattern caused
  # a real "Invalid index" error elsewhere in this module before being
  # fixed - same fix applied here proactively).
  detector_id = length(aws_guardduty_detector.this) > 0 ? aws_guardduty_detector.this[0].id : ""
}
