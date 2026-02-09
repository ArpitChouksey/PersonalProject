# VPC
vpc_cidr = "10.0.0.0/16"
vpc_name = "prod-vpc"

# Subnets
subnets = {
  public-subnet-a = {
    cidr   = "10.0.1.0/24"
    az     = "ap-south-1a"
    public = true
  }
  public-subnet-b = {
    cidr   = "10.0.2.0/24"
    az     = "ap-south-1b"
    public = true
  }
  private-subnet-a = {
    cidr   = "10.0.11.0/24"
    az     = "ap-south-1a"
    public = false
  }
  private-subnet-b = {
    cidr   = "10.0.12.0/24"
    az     = "ap-south-1b"
    public = false
  }
}

igw_name = "prod-igw"

