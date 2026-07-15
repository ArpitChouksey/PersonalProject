#########################################
# VPN
#########################################

output "vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.this.id
}

output "vpn_endpoint_arn" {
  value = aws_ec2_client_vpn_endpoint.this.arn
}

output "vpn_dns_name" {
  value = aws_ec2_client_vpn_endpoint.this.dns_name
}

output "association_id" {
  value = aws_ec2_client_vpn_network_association.this.id
}
