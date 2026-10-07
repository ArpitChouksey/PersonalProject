############################################################
# Enterprise Transit Gateway
############################################################

resource "aws_ec2_transit_gateway" "enterprise" {

  description = "Enterprise regional Transit Gateway for centralized VPC connectivity"

  amazon_side_asn = 64512

  # Existing TGW configuration
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  vpn_ecmp_support = "enable"
  dns_support      = "enable"

  security_group_referencing_support = "disable"
  multicast_support                  = "disable"

  tags = {
    Name        = "enterprise-tgw"
    Environment = "Enterprise"
    Project     = "Master-Networking"
    ManagedBy   = "Terraform"
  }
}


############################################################
# TGW Route Tables
############################################################

resource "aws_ec2_transit_gateway_route_table" "shared_services" {

  transit_gateway_id = aws_ec2_transit_gateway.enterprise.id

  tags = {
    Name        = "enterprise-tgw-rt-shared-services"
    Environment = "Enterprise"
    Project     = "Master-Networking"
    ManagedBy   = "Terraform"
  }
}


resource "aws_ec2_transit_gateway_route_table" "non_production" {

  transit_gateway_id = aws_ec2_transit_gateway.enterprise.id

  tags = {
    Name        = "enterprise-tgw-rt-non-production"
    Environment = "Enterprise"
    Project     = "Master-Networking"
    ManagedBy   = "Terraform"
  }
}


resource "aws_ec2_transit_gateway_route_table" "network" {

  transit_gateway_id = aws_ec2_transit_gateway.enterprise.id

  tags = {
    Name        = "enterprise-tgw-rt-network"
    Environment = "Enterprise"
    Project     = "Master-Networking"
    ManagedBy   = "Terraform"
  }
}


resource "aws_ec2_transit_gateway_route_table" "production" {

  transit_gateway_id = aws_ec2_transit_gateway.enterprise.id

  tags = {
    Name        = "enterprise-tgw-rt-production"
    Environment = "Enterprise"
    Project     = "Master-Networking"
    ManagedBy   = "Terraform"
  }
}


resource "aws_ec2_transit_gateway_route_table" "unnamed" {

  transit_gateway_id = aws_ec2_transit_gateway.enterprise.id
}


############################################################
# TGW VPC Attachment
############################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "network_core" {

  transit_gateway_id = aws_ec2_transit_gateway.enterprise.id

  vpc_id = aws_vpc.network_core.id

  subnet_ids = [
    "subnet-0407c2b0df7fc47a0",
    "subnet-0d3608ad0c843ec21",
    "subnet-0ee0cb20461bd4f2e"
  ]

  dns_support                        = "enable"
  security_group_referencing_support = "enable"
  ipv6_support                       = "disable"
  appliance_mode_support             = "disable"

  tags = {
    Name        = "network-core-tgw-attachment"
    Environment = "Enterprise"
    Project     = "Master-Networking"
    ManagedBy   = "Terraform"
  }
}


############################################################
# TGW Route Table Associations
############################################################

# Network VPC -> Network TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "network_core" {

  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.network_core.id

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.network.id
}


# Azure VPN 01 -> Network TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "azure_01" {

  transit_gateway_attachment_id = "tgw-attach-077a385e49ce9e619"

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.network.id
}


# Azure VPN 02 -> Network TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "azure_02" {

  transit_gateway_attachment_id = "tgw-attach-08a286e2c2d540f1e"

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.network.id
}


############################################################
# TGW Route Table Propagations
############################################################

# Network VPC -> Network TGW Route Table
resource "aws_ec2_transit_gateway_route_table_propagation" "network_core" {

  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.network_core.id

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.network.id
}


# Azure VPN 01 -> Network TGW Route Table
resource "aws_ec2_transit_gateway_route_table_propagation" "azure_01" {

  transit_gateway_attachment_id = "tgw-attach-077a385e49ce9e619"

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.network.id
}


# Azure VPN 02 -> Network TGW Route Table
resource "aws_ec2_transit_gateway_route_table_propagation" "azure_02" {

  transit_gateway_attachment_id = "tgw-attach-08a286e2c2d540f1e"

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.network.id
}
