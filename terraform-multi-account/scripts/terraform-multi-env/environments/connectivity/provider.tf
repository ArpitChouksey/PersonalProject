terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = var.terraform_execution_role
  }

  default_tags {
    tags = {
      Environment = "connectivity"
      ManagedBy   = "Terraform"
      Project     = "terraform-multi-env"
    }
  }
}
