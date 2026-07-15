###########################################
# VPC
###########################################

output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_arn" {
  value = aws_vpc.this.arn
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

###########################################
# Application Subnet
###########################################

output "app_subnet_id" {
  value = aws_subnet.app.id
}

output "app_subnet_arn" {
  value = aws_subnet.app.arn
}

###########################################
# Database Subnet
###########################################

output "db_subnet_id" {
  value = aws_subnet.db.id
}

output "db_subnet_arn" {
  value = aws_subnet.db.arn
}

###########################################
# Route Tables
###########################################

output "app_route_table_id" {
  value = aws_route_table.app.id
}

output "db_route_table_id" {
  value = aws_route_table.db.id
}
