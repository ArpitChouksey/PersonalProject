###############################################################################
# Terraform Configuration
###############################################################################

terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

###############################################################################
# AWS Provider
###############################################################################

provider "aws" {
  profile = "network"
  region  = "us-east-1"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = "Enterprise"
      Project     = "Master-Networking"
      Account     = "Network"
    }
  }
}
