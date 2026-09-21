# ============================================================
# VPC
# ============================================================

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}


# ============================================================
# PUBLIC SUBNETS
# ============================================================

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [
    for subnet in aws_subnet.public : subnet.id
  ]
}


# ============================================================
# PRIVATE SUBNETS
# ============================================================

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = [
    for subnet in aws_subnet.private : subnet.id
  ]
}


# ============================================================
# INTERNET GATEWAY
# ============================================================

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}


# ============================================================
# ROUTE TABLES
# ============================================================

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = aws_route_table.private.id
}
