terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"

  assume_role {
    role_arn = "arn:aws:iam::796761618375:role/TerraformExecutionRole"
  }

  default_tags {
    tags = {
      Project     = "terraform-multi-env"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
