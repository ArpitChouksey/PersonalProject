module "account_baseline" {
  source = "../../../modules/account-baseline"

  account_name = var.account_name
  environment  = var.environment
  region       = var.aws_region
}
