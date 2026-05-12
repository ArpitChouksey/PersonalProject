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
  region  = "us-east-1"
  profile = "dev"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
      Project     = "shared-vpc-platform"
    }
  }
}

#provider "aws" {
#  region = "ap-south-1"
#  profile = "dev"

#  assume_role {
#    role_arn = "arn:aws:iam::119004746935:role/TerraformExecutionRole"
#  }

#  default_tags {
#    tags = {
#      Project     = "terraform-multi-env"
#      Environment = "dev"
#      ManagedBy   = "terraform"
#    }
#  }
#}
