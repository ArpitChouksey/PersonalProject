###############################################################
# Backend
#
# Local backend for now, so `terraform init` works out of the
# box while we test scenarios. Switch to the commented S3 backend
# once a state bucket + lock table exist for this account.
###############################################################

# terraform {
#   backend "s3" {
#     bucket         = "company-terraform-state-dev"
#     key            = "api-gateway/dev/us-west-2/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-dev"
#     encrypt        = true
#   }
# }
