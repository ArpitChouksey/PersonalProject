#########################################
# Client VPN Endpoint
#########################################

resource "aws_ec2_client_vpn_endpoint" "this" {

  description            = var.vpn_name

  client_cidr_block      = var.client_cidr_block

  server_certificate_arn = var.server_certificate_arn

  transport_protocol     = var.transport_protocol

  vpn_port               = var.vpn_port

  split_tunnel           = var.split_tunnel

  session_timeout_hours  = var.session_timeout_hours

  dns_servers            = var.dns_servers

  authentication_options {

    type                       = "certificate-authentication"

    root_certificate_chain_arn = var.root_certificate_chain_arn

  }

  connection_log_options {

    enabled = false

  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-client-vpn"
    }
  )

}

#########################################
# Target Network Association
#########################################

resource "aws_ec2_client_vpn_network_association" "this" {

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id

  subnet_id = var.target_subnet_id

}

#########################################
# Authorization Rule
#########################################

resource "aws_ec2_client_vpn_authorization_rule" "this" {

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id

  target_network_cidr = var.destination_cidr_block

  authorize_all_groups = var.authorize_all_groups

}

#########################################
# Route : Already managed by aws
#########################################

#resource "aws_ec2_client_vpn_route" "this" {

#  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id

#  destination_cidr_block = var.destination_cidr_block

#  target_vpc_subnet_id = var.target_subnet_id

#}
