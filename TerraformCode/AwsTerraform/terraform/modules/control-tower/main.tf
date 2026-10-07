resource "aws_controltower_landing_zone" "this" {
  version = var.landing_zone_version

  manifest_json = var.manifest_json

  remediation_types = [
    "INHERITANCE_DRIFT"
  ]

  lifecycle {
    prevent_destroy = true
  }
}
