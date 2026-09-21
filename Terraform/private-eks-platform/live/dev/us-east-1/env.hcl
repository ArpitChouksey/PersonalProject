locals {
  environment = "dev"

  project_name = "private-eks-platform"

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnets = {
    public_a = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
    }

    public_b = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
    }
  }

  private_subnets = {
    private_a = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-east-1a"
    }

    private_b = {
      cidr_block        = "10.0.12.0/24"
      availability_zone = "us-east-1b"
    }
  }

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_flow_logs     = true

  common_tags = {
    Project     = "private-eks-platform"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
