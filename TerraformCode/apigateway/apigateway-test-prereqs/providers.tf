###############################################################
# Provider
###############################################################

provider "aws" {

  region  = var.aws_region

  profile = var.aws_profile

  default_tags {

    tags = {
      ManagedBy = "Terraform"
      Purpose   = "apigateway-test-prereqs-minimal"
      Ephemeral = "true"
    }

  }

}
