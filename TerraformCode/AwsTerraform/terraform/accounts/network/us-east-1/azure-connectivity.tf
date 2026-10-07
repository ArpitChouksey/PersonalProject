############################################
# Azure Customer Gateways
############################################

resource "aws_customer_gateway" "azure_01" {
  bgp_asn    = var.azure_bgp_asn
  ip_address = var.azure_vpn_gateway_public_ip_01
  type       = "ipsec.1"

  tags = {
    Name = "cgw-azure-vpn-01"
  }
}

resource "aws_customer_gateway" "azure_02" {
  bgp_asn    = var.azure_bgp_asn
  ip_address = var.azure_vpn_gateway_public_ip_02
  type       = "ipsec.1"

  tags = {
    Name = "cgw-azure-vpn-02"
  }
}


############################################
# AWS VPN Connection - Azure VPN Gateway 01
############################################

resource "aws_vpn_connection" "azure_01" {
  customer_gateway_id = aws_customer_gateway.azure_01.id
  transit_gateway_id  = var.transit_gateway_id

  type = "ipsec.1"

  static_routes_only = false

  tunnel1_inside_cidr = "169.254.21.0/30"
  tunnel2_inside_cidr = "169.254.22.0/30"

  tags = {
    Name = "vpn-azure-tgw-01"
  }
}


############################################
# AWS VPN Connection - Azure VPN Gateway 02
############################################

resource "aws_vpn_connection" "azure_02" {
  customer_gateway_id = aws_customer_gateway.azure_02.id
  transit_gateway_id  = var.transit_gateway_id

  type = "ipsec.1"

  static_routes_only = false

  tunnel1_inside_cidr = "169.254.21.4/30"
  tunnel2_inside_cidr = "169.254.22.4/30"

  tags = {
    Name = "vpn-azure-tgw-02"
  }
}
