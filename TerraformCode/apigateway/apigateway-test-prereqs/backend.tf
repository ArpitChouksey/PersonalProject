###############################################################
# Backend -- local state, entirely separate from
# deployments/<env>/<region>'s state.
###############################################################

# terraform {
#   backend "s3" {
#     bucket = "company-terraform-state-dev"
#     key    = "api-gateway-test-prereqs-min/terraform.tfstate"
#     region = "us-west-2"
#   }
# }
