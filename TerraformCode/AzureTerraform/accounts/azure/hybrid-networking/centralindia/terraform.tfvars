subscription_id = "440b48d6-073f-4588-9499-24c49906a898"

resource_group_name = "rg-hybrid-networking"
location            = "centralindia"

vnet_name          = "vnet-hybrid-azure"
vnet_address_space = ["10.20.0.0/16"]

workload_subnet_name             = "snet-workload"
workload_subnet_address_prefixes = ["10.20.1.0/24"]
gateway_subnet_address_prefixes  = ["10.20.255.0/24"]

public_ip_01_name = "pip-vpngw-azure"
public_ip_02_name = "pip-vpngw-azure-02"

vpn_gateway_name       = "vng-hybrid-azure"
vpn_gateway_sku        = "VpnGw2AZ"
vpn_gateway_generation = "Generation2"

azure_bgp_asn = 65515

azure_bgp_apipa_primary_01   = "169.254.21.2"
azure_bgp_apipa_secondary_01 = "169.254.22.2"

azure_bgp_apipa_primary_02   = "169.254.21.6"
azure_bgp_apipa_secondary_02 = "169.254.22.6"

aws_local_network_gateways = {
  aws_tgw_01_t1 = {
    name                = "lng-aws-tgw-01-t1"
    gateway_address     = "34.239.234.228"
    bgp_asn             = 64512
    bgp_peering_address = "169.254.21.1"
  }

  aws_tgw_01_t2 = {
    name                = "lng-aws-tgw-01-t2"
    gateway_address     = "100.27.76.0"
    bgp_asn             = 64512
    bgp_peering_address = "169.254.22.1"
  }

  aws_tgw_02_t1 = {
    name                = "lng-aws-tgw-02-t1"
    gateway_address     = "3.216.209.232"
    bgp_asn             = 64512
    bgp_peering_address = "169.254.21.5"
  }

  aws_tgw_02_t2 = {
    name                = "lng-aws-tgw-02-t2"
    gateway_address     = "34.232.29.55"
    bgp_asn             = 64512
    bgp_peering_address = "169.254.22.5"
  }
}

aws_connections = {
  aws_tgw_01_t1 = {
    name                      = "conn-aws-tgw-01-t1"
    local_network_gateway_key = "aws_tgw_01_t1"
    custom_bgp_primary        = "169.254.21.2"
    custom_bgp_secondary      = "169.254.21.6"
  }

  aws_tgw_01_t2 = {
    name                      = "conn-aws-tgw-01-t2"
    local_network_gateway_key = "aws_tgw_01_t2"
    custom_bgp_primary        = "169.254.22.2"
    custom_bgp_secondary      = "169.254.22.6"
  }

  aws_tgw_02_t1 = {
    name                      = "conn-aws-tgw-02-t1"
    local_network_gateway_key = "aws_tgw_02_t1"
    custom_bgp_primary        = "169.254.21.2"
    custom_bgp_secondary      = "169.254.21.6"
  }

  aws_tgw_02_t2 = {
    name                      = "conn-aws-tgw-02-t2"
    local_network_gateway_key = "aws_tgw_02_t2"
    custom_bgp_primary        = "169.254.21.2"
    custom_bgp_secondary      = "169.254.22.6"
  }
}

# Existing PSKs from the AWS VPN configuration files.
# Mapping:
# aws_tgw_01_t1 -> vpn-09661d881516baf0f Tunnel #1
# aws_tgw_01_t2 -> vpn-09661d881516baf0f Tunnel #2
# aws_tgw_02_t1 -> vpn-0941751367b0ed511 Tunnel #1
# aws_tgw_02_t2 -> vpn-0941751367b0ed511 Tunnel #2

aws_shared_keys = {
  aws_tgw_01_t1 = "9xA_j0.FMVwtaq0eVGX6HXjLu95gHTfi"
  aws_tgw_01_t2 = "3saH7njubH8FK31_E2ZpYrc_8XzmleJK"
  aws_tgw_02_t1 = "lpe18OK4.THkNvqdtypLeMQq.5jGOZwO"
  aws_tgw_02_t2 = "NZ9DDQUlnEVc99_FTDXQAP1.6faODhDx"
}

tags = {
  Environment = "hybrid"
  Project     = "master-networking"
  Component   = "azure-vpn"
  ManagedBy   = "terraform"
}
