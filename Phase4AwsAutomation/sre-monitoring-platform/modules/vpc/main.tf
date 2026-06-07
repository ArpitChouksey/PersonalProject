resource "aws_vpc" "main" {

  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true

  enable_dns_support = true

  tags = {
    Name = "sre-vpc"
  }
}

##################################################
# PUBLIC SUBNETS
##################################################

resource "aws_subnet" "public_a" {

  vpc_id = aws_vpc.main.id

  cidr_block = var.public_subnet_a_cidr

  availability_zone = "us-east-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {

  vpc_id = aws_vpc.main.id

  cidr_block = var.public_subnet_b_cidr

  availability_zone = "us-east-1b"

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}

##################################################
# PRIVATE SUBNETS
##################################################

resource "aws_subnet" "private_a" {

  vpc_id = aws_vpc.main.id

  cidr_block = var.private_subnet_a_cidr

  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {

  vpc_id = aws_vpc.main.id

  cidr_block = var.private_subnet_b_cidr

  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-b"
  }
}

##################################################
# INTERNET GATEWAY
##################################################

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "sre-igw"
  }
}

##################################################
# ELASTIC IP
##################################################

resource "aws_eip" "nat" {

  domain = "vpc"

  tags = {
    Name = "sre-nat-eip"
  }
}

##################################################
# NAT GATEWAY
##################################################

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat.id

  subnet_id = aws_subnet.public_a.id

  tags = {
    Name = "sre-natgw"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

##################################################
# ROUTE TABLES
##################################################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

##################################################
# ASSOCIATIONS
##################################################

resource "aws_route_table_association" "public_a" {

  subnet_id = aws_subnet.public_a.id

  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {

  subnet_id = aws_subnet.public_b.id

  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {

  subnet_id = aws_subnet.private_a.id

  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {

  subnet_id = aws_subnet.private_b.id

  route_table_id = aws_route_table.private.id
}
