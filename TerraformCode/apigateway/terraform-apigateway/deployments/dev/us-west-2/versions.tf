###############################################################
# Terraform & Provider Requirements
###############################################################

terraform {

  required_version = ">= 1.13.0"

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }

  }

}
