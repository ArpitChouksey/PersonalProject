module "identity_center" {
  source = "../modules/identity-center"

  identity_store_id = var.identity_store_id

  permission_sets = var.permission_sets

  users = var.users

  account_assignments = var.account_assignments
}
