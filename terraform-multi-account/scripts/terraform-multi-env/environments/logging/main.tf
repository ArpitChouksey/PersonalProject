module "terraform_execution_role" {
  source = "../../modules/terraform-role"

  role_name             = "TerraformExecutionRole"
  management_account_id = "211811255273"
  environment           = "logging"
}
