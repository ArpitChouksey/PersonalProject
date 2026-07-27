###############################################################
# Provider
###############################################################

provider "aws" {

  region  = var.aws_region

  profile = var.aws_profile

  default_tags {

    tags = {
      ManagedBy = "Terraform"
      Project   = var.project_name
      Environment = var.environment
    }

  }

}
