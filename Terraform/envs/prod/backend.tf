terraform {
  backend "s3" {
    bucket         = "arpit-terraform-eks-state"
    key            = "aws-eks-project/prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

