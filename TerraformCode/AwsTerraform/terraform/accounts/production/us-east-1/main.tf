############################################
# Production VPC
############################################

resource "aws_vpc" "production" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}


############################################
# Private Subnets
############################################

resource "aws_subnet" "private" {
  for_each = var.subnets

  vpc_id            = aws_vpc.production.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.value.name
  }
}


############################################
# Private Route Table
############################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.production.id

  tags = {
    Name = var.route_table_name
  }
}


############################################
# Route Table Associations
############################################

resource "aws_route_table_association" "private" {
  for_each = var.subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}


############################################
# Routes → Enterprise TGW
############################################

resource "aws_route" "tgw" {
  for_each = var.routes

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = each.value.destination_cidr
  transit_gateway_id     = var.transit_gateway_id
}


############################################
# Production VPC → Enterprise TGW
############################################

resource "aws_ec2_transit_gateway_vpc_attachment" "production" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.production.id

  subnet_ids = [
    aws_subnet.private["private_a"].id,
    aws_subnet.private["private_b"].id
  ]

  dns_support = "enable"

  tags = {
    Name = var.transit_gateway_attachment_name
  }
}
