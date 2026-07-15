###########################################
# VPC
###########################################

resource "aws_vpc" "this" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )
}

###########################################
# Application Subnet
###########################################

resource "aws_subnet" "app" {

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.app_subnet_cidr
  availability_zone       = var.app_subnet_az
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app-subnet"
    }
  )
}

###########################################
# Database Subnet
###########################################

resource "aws_subnet" "db" {

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.db_subnet_cidr
  availability_zone       = var.db_subnet_az
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-db-subnet"
    }
  )
}

###########################################
# Application Route Table
###########################################

resource "aws_route_table" "app" {

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app-rt"
    }
  )
}

###########################################
# Database Route Table
###########################################

resource "aws_route_table" "db" {

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-db-rt"
    }
  )
}

###########################################
# Route Table Association
###########################################

resource "aws_route_table_association" "app" {

  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.app.id

}

resource "aws_route_table_association" "db" {

  subnet_id      = aws_subnet.db.id
  route_table_id = aws_route_table.db.id

}
