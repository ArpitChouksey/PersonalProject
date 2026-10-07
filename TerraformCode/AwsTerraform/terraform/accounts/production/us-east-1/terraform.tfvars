aws_region  = "us-east-1"
aws_profile = "production"

vpc_cidr = "10.40.0.0/16"

vpc_name = "enterprise-production-vpc"

subnets = {
  private_a = {
    cidr_block        = "10.40.1.0/24"
    availability_zone = "us-east-1a"
    name              = "enterprise-prod-private-a"
  }

  private_b = {
    cidr_block        = "10.40.2.0/24"
    availability_zone = "us-east-1b"
    name              = "enterprise-prod-private-b"
  }
}

route_table_name = "enterprise-production-private-rt"

transit_gateway_id = "tgw-0a8bb2ec2e645f5ad"

transit_gateway_attachment_name = "enterprise-production-tgw-attachment"

routes = {
  shared_services = {
    destination_cidr = "10.30.0.0/16"
  }
}
