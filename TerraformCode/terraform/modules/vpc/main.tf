
################################
# PUBLIC / ALB SECURITY GROUP
################################
resource "aws_security_group" "public" {
  vpc_id     = var.vpc_id
  name       = "proj-alb-sg"
  description = "ALB security group"

#  lifecycle {
#    ignore_changes = [
#      ingress,
#      egress,
#      description
#    ]
#  }

  tags = merge(var.tags, {
    Name = "proj-alb-sg"
  })
}

################################
# APP SECURITY GROUP
################################
resource "aws_security_group" "app" {
  vpc_id     = var.vpc_id
  name       = "proj-app-sg"
  description = "Application EC2 security group"

#  lifecycle {
#    ignore_changes = [
#      ingress,
#      egress,
#      description
#    ]
#  }

  tags = merge(var.tags, {
    Name = "proj-app-sg"
  })
}

################################
# DB SECURITY GROUP
################################
resource "aws_security_group" "db" {
  vpc_id     = var.vpc_id
  name       = "proj-db-sg"
  description = "Allow ec2 to edit "

#  lifecycle {
#    ignore_changes = [
#      ingress,
#      egress,
#      description
#    ]
#  }

  tags = merge(var.tags, {
    Name = "proj-db-sg"
  })
}



################################
# EXISTING VPC (DATA SOURCE)
################################
data "aws_vpc" "this" {
  id = var.vpc_id
}

################################
# EXISTING IGW (DATA SOURCE)
################################

data "aws_internet_gateway" "this" {
  filter {
    name   = "internet-gateway-id"
    values = [var.igw_id]
  }
}

################################
# PRIVATE INTERNET ROUTE (NAT)
################################
resource "aws_route" "private_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}



################################
# PUBLIC SUBNETS
################################
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = data.aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    { Name = each.key }
  )
}

################################
# PRIVATE SUBNETS
################################
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = data.aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.tags,
    { Name = each.key }
  )
}

################################
# PUBLIC ROUTE TABLE
################################
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.this.id

  tags = merge(
    var.tags,
    { Name = "proj-public-rt" }
  )
}

################################
# INTERNET ROUTE (NO CHANGE)
################################
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.this.id
}

################################
# ROUTE TABLE ASSOCIATIONS
################################
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

