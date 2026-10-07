module "control_tower" {
  source = "../modules/control-tower"

  landing_zone_version = var.landing_zone_version
  manifest_json        = var.manifest_json
}
