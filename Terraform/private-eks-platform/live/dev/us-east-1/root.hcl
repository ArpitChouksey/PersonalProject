locals {
  region_config = read_terragrunt_config(
    find_in_parent_folders("region.hcl")
  )

  environment_config = read_terragrunt_config(
    find_in_parent_folders("env.hcl")
  )

  aws_region = local.region_config.locals.aws_region

  environment = local.environment_config.locals.environment

  project_name = local.environment_config.locals.project_name

  common_tags = local.environment_config.locals.common_tags
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"

  contents = <<EOF_PROVIDER
terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project     = "${local.project_name}"
      Environment = "${local.environment}"
      ManagedBy   = "Terraform"
    }
  }
}
EOF_PROVIDER
}
