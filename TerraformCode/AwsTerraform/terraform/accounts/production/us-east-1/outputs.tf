output "vpc_id" {
  description = "Production VPC ID"
  value       = aws_vpc.production.id
}

output "vpc_cidr" {
  description = "Production VPC CIDR"
  value       = aws_vpc.production.cidr_block
}

output "private_subnet_ids" {
  description = "Production private subnet IDs"

  value = {
    for key, subnet in aws_subnet.private :
    key => subnet.id
  }
}

output "private_route_table_id" {
  description = "Production private route table ID"
  value       = aws_route_table.private.id
}

output "transit_gateway_id" {
  description = "Enterprise Transit Gateway ID"
  value       = var.transit_gateway_id
}

output "transit_gateway_attachment_id" {
  description = "Production TGW attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.production.id
}
