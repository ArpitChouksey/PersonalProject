module "azure_hybrid_networking" {
  source = "../../../../modules/azure-hybrid-networking"

  resource_group_name = var.resource_group_name
  location            = var.location

  vnet_name          = var.vnet_name
  vnet_address_space = var.vnet_address_space

  workload_subnet_name             = var.workload_subnet_name
  workload_subnet_address_prefixes = var.workload_subnet_address_prefixes
  gateway_subnet_address_prefixes  = var.gateway_subnet_address_prefixes

  public_ip_01_name = var.public_ip_01_name
  public_ip_02_name = var.public_ip_02_name

  vpn_gateway_name       = var.vpn_gateway_name
  vpn_gateway_sku        = var.vpn_gateway_sku
  vpn_gateway_generation = var.vpn_gateway_generation

  azure_bgp_asn = var.azure_bgp_asn

  azure_bgp_apipa_primary_01   = var.azure_bgp_apipa_primary_01
  azure_bgp_apipa_secondary_01 = var.azure_bgp_apipa_secondary_01

  azure_bgp_apipa_primary_02   = var.azure_bgp_apipa_primary_02
  azure_bgp_apipa_secondary_02 = var.azure_bgp_apipa_secondary_02

  aws_local_network_gateways = var.aws_local_network_gateways

  aws_connections = var.aws_connections

  aws_shared_keys = var.aws_shared_keys

  tags = var.tags
}
