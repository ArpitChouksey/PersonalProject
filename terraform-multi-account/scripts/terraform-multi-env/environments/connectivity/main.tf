#############################################
# TERRAFORM EXECUTION ROLE MODULE
#############################################

module "terraform_execution_role" {
  source = "../../modules/terraform-role"

  role_name             = "TerraformExecutionRole"
  management_account_id = "211811255273"
  environment           = "connectivity"
}

#############################################
# VPC
#############################################

resource "aws_vpc" "connectivity_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "connectivity-vpc"
    Environment = "connectivity"
  }
}

#############################################
# PUBLIC SUBNET AZ1
#############################################

resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.connectivity_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az1"
  }
}

#############################################
# PUBLIC SUBNET AZ2
#############################################

resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.connectivity_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az2"
  }
}

#############################################
# PRIVATE SUBNET AZ1
#############################################

resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = aws_vpc.connectivity_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-az1"
  }
}

#############################################
# PRIVATE SUBNET AZ2
#############################################

resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = aws_vpc.connectivity_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-az2"
  }
}

#############################################
# INTERNET GATEWAY
#############################################

resource "aws_internet_gateway" "connectivity_igw" {
  vpc_id = aws_vpc.connectivity_vpc.id

  tags = {
    Name = "connectivity-igw"
  }
}

#############################################
# PUBLIC ROUTE TABLE
#############################################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.connectivity_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.connectivity_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

#############################################
# PRIVATE ROUTE TABLE
#############################################

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.connectivity_vpc.id

  tags = {
    Name = "private-rt"
  }
}

#############################################
# ELASTIC IP
#############################################

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "connectivity-nat-eip"
  }
}

#############################################
# NAT GATEWAY
#############################################

resource "aws_nat_gateway" "connectivity_nat" {
  allocation_id     = aws_eip.nat_eip.id
  subnet_id         = aws_subnet.public_subnet_az1.id
  connectivity_type = "public"

  tags = {
    Name        = "connectivity-nat"
    Environment = "connectivity"
  }

  depends_on = [
    aws_internet_gateway.connectivity_igw
  ]

  #lifecycle {
  #  prevent_destroy = true
  #}
}


#############################################
# PRIVATE ROUTE TO NAT
#############################################

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.connectivity_nat.id
}

#############################################
# PUBLIC ROUTE TABLE ASSOCIATIONS
#############################################

resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_rt.id
}

#############################################
# PRIVATE ROUTE TABLE ASSOCIATIONS
#############################################

resource "aws_route_table_association" "private_az1_assoc" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_az2_assoc" {
  subnet_id      = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_rt.id
}
