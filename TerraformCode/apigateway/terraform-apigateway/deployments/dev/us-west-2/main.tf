###############################################################
# API Gateway — dev / us-west-2
###############################################################

module "apigateway" {

  source = "../../../modules/apigateway"

  #############################################################
  # Global / Tagging
  #############################################################

  project_name      = var.project_name
  environment       = var.environment
  aws_region        = var.aws_region
  aws_profile       = var.aws_profile
  owner             = var.owner
  cost_center       = var.cost_center
  business_unit     = var.business_unit
  terraform_version = var.terraform_version
  tags              = var.tags

  #############################################################
  # API Definitions
  #############################################################

  api_definition_path     = local.api_definition_path
  openapi_definition_path = local.openapi_definition_path

}
