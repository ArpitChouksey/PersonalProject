terraform {
  backend "s3" {
    bucket         = "sre-monitoring-tf-state"
    key            = "sre-monitoring/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
