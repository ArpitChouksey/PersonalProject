aws_region  = "us-east-1"
aws_profile = "sharedservices"

vpc_cidr = "10.30.0.0/16"

vpc_name = "enterprise-shared-services-vpc"

subnets = {
  private_a = {
    cidr_block        = "10.30.1.0/24"
    availability_zone = "us-east-1a"
    name              = "enterprise-shared-private-a"
  }

  private_b = {
    cidr_block        = "10.30.2.0/24"
    availability_zone = "us-east-1b"
    name              = "enterprise-shared-private-b"
  }
}

route_table_name = "enterprise-shared-private-rt"

transit_gateway_id = "tgw-0a8bb2ec2e645f5ad"

transit_gateway_attachment_name = "enterprise-shared-services-tgw-attachment"

routes = {
  network = {
    destination_cidr = "10.0.0.0/20"
  }

  production = {
    destination_cidr = "10.40.0.0/16"
  }
}
