module "organization" {
  source = "../modules/organization"

  organization_id          = var.organization_id
  management_account_id    = var.management_account_id
  organizational_units     = var.organizational_units
  accounts                 = var.accounts
  service_control_policies = var.service_control_policies
}
