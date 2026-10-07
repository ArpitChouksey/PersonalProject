output "vpc_id" {
  description = "Shared Services VPC ID"
  value       = aws_vpc.shared_services.id
}

output "vpc_cidr" {
  description = "Shared Services VPC CIDR"
  value       = aws_vpc.shared_services.cidr_block
}

output "private_subnet_ids" {
  description = "Shared Services private subnet IDs"
  value = {
    for key, subnet in aws_subnet.private :
    key => subnet.id
  }
}

output "private_route_table_id" {
  description = "Shared Services private route table ID"
  value       = aws_route_table.private.id
}

output "transit_gateway_id" {
  description = "Enterprise Transit Gateway ID"
  value       = var.transit_gateway_id
}

output "transit_gateway_attachment_id" {
  description = "Shared Services TGW attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.shared_services.id
}
