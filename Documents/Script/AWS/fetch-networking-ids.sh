#!/bin/bash

set -e

PROFILE="network"
REGION="us-east-1"

echo
echo "=========================================="
echo " AWS MASTER NETWORKING RESOURCE DISCOVERY"
echo "=========================================="
echo
echo "Profile : $PROFILE"
echo "Region  : $REGION"
echo "=========================================="

# ------------------------------------------------------------
# AWS ACCOUNT
# ------------------------------------------------------------

echo
echo "=== AWS ACCOUNT ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws sts get-caller-identity \
  --profile "$PROFILE" \
  --output table


# ------------------------------------------------------------
# IPAM
# ------------------------------------------------------------

echo
echo "=== IPAM ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-ipams \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Ipams[*].{
    IpamId:IpamId,
    Name:Tags[?Key==`Name`]|[0].Value,
    State:State,
    Tier:Tier,
    DefaultPrivateScopeId:PrivateDefaultScopeId,
    DefaultPublicScopeId:PublicDefaultScopeId
  }' \
  --output table


# ------------------------------------------------------------
# IPAM POOLS
# ------------------------------------------------------------

echo
echo "=== IPAM POOLS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-ipam-pools \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'IpamPools[*].{
    PoolId:IpamPoolId,
    Name:Tags[?Key==`Name`]|[0].Value,
    AddressFamily:AddressFamily,
    Locale:Locale,
    ParentPoolId:SourceIpamPoolId,
    State:State,
    Description:Description
  }' \
  --output table


# ------------------------------------------------------------
# IPAM POOL CIDRS
# ------------------------------------------------------------

echo
echo "=== IPAM POOL CIDRS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

for POOL_ID in \
  "ipam-pool-0a3fb3d6511ea189f" \
  "ipam-pool-0fab3acab0edf1768"
do

  echo
  echo "Pool: $POOL_ID"

  aws ec2 get-ipam-pool-cidrs \
    --ipam-pool-id "$POOL_ID" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'IpamPoolCidrs[*].{
      Cidr:Cidr,
      State:State,
      CidrId:IpamPoolCidrId
    }' \
    --output table

done


# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

echo
echo "=== VPC ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-vpcs \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Vpcs[*].{
    VpcId:VpcId,
    Name:Tags[?Key==`Name`]|[0].Value,
    CIDR:CidrBlock,
    State:State,
    IsDefault:IsDefault
  }' \
  --output table


# ------------------------------------------------------------
# SUBNETS
# ------------------------------------------------------------

echo
echo "=== SUBNETS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-subnets \
  --profile "$PROFILE" \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=vpc-0e0311231e766e555" \
  --query 'Subnets[*].{
    SubnetId:SubnetId,
    Name:Tags[?Key==`Name`]|[0].Value,
    VpcId:VpcId,
    AZ:AvailabilityZone,
    CIDR:CidrBlock,
    State:State
  }' \
  --output table


# ------------------------------------------------------------
# INTERNET GATEWAYS
# ------------------------------------------------------------

echo
echo "=== INTERNET GATEWAYS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-internet-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'InternetGateways[*].{
    InternetGatewayId:InternetGatewayId,
    Name:Tags[?Key==`Name`]|[0].Value,
    State:Attachments[0].State,
    VpcId:Attachments[0].VpcId
  }' \
  --output table


# ------------------------------------------------------------
# ELASTIC IPS
# ------------------------------------------------------------

echo
echo "=== ELASTIC IPs ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-addresses \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Addresses[*].{
    AllocationId:AllocationId,
    AssociationId:AssociationId,
    PublicIp:PublicIp,
    NetworkInterfaceId:NetworkInterfaceId,
    InstanceId:InstanceId,
    Domain:Domain
  }' \
  --output table


# ------------------------------------------------------------
# NAT GATEWAYS
# ------------------------------------------------------------

echo
echo "=== NAT GATEWAYS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-nat-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --filter "Name=vpc-id,Values=vpc-0e0311231e766e555" \
  --query 'NatGateways[*].{
    NatGatewayId:NatGatewayId,
    Name:Tags[?Key==`Name`]|[0].Value,
    State:State,
    SubnetId:SubnetId,
    AllocationId:NatGatewayAddresses[0].AllocationId,
    PublicIp:NatGatewayAddresses[0].PublicIp
  }' \
  --output table


# ------------------------------------------------------------
# ROUTE TABLES
# ------------------------------------------------------------

echo
echo "=== ROUTE TABLES ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-route-tables \
  --profile "$PROFILE" \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=vpc-0e0311231e766e555" \
  --query 'RouteTables[*].{
    RouteTableId:RouteTableId,
    Name:Tags[?Key==`Name`]|[0].Value,
    VpcId:VpcId,
    Associations:Associations[*].SubnetId,
    Routes:Routes[*].{
      Destination:DestinationCidrBlock,
      GatewayId:GatewayId,
      NatGatewayId:NatGatewayId,
      TransitGatewayId:TransitGatewayId,
      NetworkInterfaceId:NetworkInterfaceId,
      State:State
    }
  }' \
  --output json


# ------------------------------------------------------------
# TRANSIT GATEWAYS
# ------------------------------------------------------------

echo
echo "=== TRANSIT GATEWAYS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-transit-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'TransitGateways[*].{
    TransitGatewayId:TransitGatewayId,
    Name:Tags[?Key==`Name`]|[0].Value,
    State:State,
    ASN:Options.AmazonSideAsn,
    DefaultRouteTableId:Options.AssociationDefaultRouteTableId,
    DefaultPropagationRouteTableId:Options.PropagationDefaultRouteTableId
  }' \
  --output table


# ------------------------------------------------------------
# TGW ROUTE TABLES
# ------------------------------------------------------------

echo
echo "=== TGW ROUTE TABLES ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-transit-gateway-route-tables \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'TransitGatewayRouteTables[*].{
    RouteTableId:TransitGatewayRouteTableId,
    Name:Tags[?Key==`Name`]|[0].Value,
    TransitGatewayId:TransitGatewayId,
    State:State,
    DefaultAssociation:DefaultAssociationRouteTable,
    DefaultPropagation:DefaultPropagationRouteTable
  }' \
  --output table


# ------------------------------------------------------------
# TGW VPC ATTACHMENTS
# ------------------------------------------------------------

echo
echo "=== TGW VPC ATTACHMENTS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws ec2 describe-transit-gateway-vpc-attachments \
  --profile "$PROFILE" \
  --region "$REGION" \
  --filters "Name=transit-gateway-id,Values=tgw-0a8bb2ec2e645f5ad" \
  --query 'TransitGatewayVpcAttachments[*].{
    AttachmentId:TransitGatewayAttachmentId,
    Name:Tags[?Key==`Name`]|[0].Value,
    State:State,
    TGWId:TransitGatewayId,
    VpcId:VpcId,
    SubnetIds:SubnetIds
  }' \
  --output table


# ------------------------------------------------------------
# TGW ROUTE TABLE ASSOCIATIONS
# ------------------------------------------------------------

echo
echo "=== TGW ROUTE TABLE ASSOCIATIONS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

for RTB_ID in \
  "tgw-rtb-004c316686a962135" \
  "tgw-rtb-03b142331aa99cd08" \
  "tgw-rtb-0c93c9241c859bc3b" \
  "tgw-rtb-0d9533c15a8b2f64d"
do

  echo
  echo "Route Table: $RTB_ID"

  aws ec2 get-transit-gateway-route-table-associations \
    --transit-gateway-route-table-id "$RTB_ID" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Associations[*].{
      ResourceId:ResourceId,
      ResourceType:ResourceType,
      State:State,
      AttachmentId:TransitGatewayAttachmentId
    }' \
    --output table

done


# ------------------------------------------------------------
# TGW ROUTE TABLE PROPAGATIONS
# ------------------------------------------------------------

echo
echo "=== TGW ROUTE TABLE PROPAGATIONS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

for RTB_ID in \
  "tgw-rtb-004c316686a962135" \
  "tgw-rtb-03b142331aa99cd08" \
  "tgw-rtb-0c93c9241c859bc3b" \
  "tgw-rtb-0d9533c15a8b2f64d"
do

  echo
  echo "Route Table: $RTB_ID"

  aws ec2 get-transit-gateway-route-table-propagations \
    --transit-gateway-route-table-id "$RTB_ID" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'TransitGatewayRouteTablePropagations[*].{
      ResourceId:ResourceId,
      ResourceType:ResourceType,
      State:State,
      AttachmentId:TransitGatewayAttachmentId,
      AnnouncementId:TransitGatewayRouteTableAnnouncementId
    }' \
    --output table

done


# ------------------------------------------------------------
# CLOUD WAN - GLOBAL NETWORK
# ------------------------------------------------------------

echo
echo "=== CLOUD WAN GLOBAL NETWORK ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws networkmanager describe-global-networks \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'GlobalNetworks[*].{
    GlobalNetworkId:GlobalNetworkId,
    Description:Description,
    State:State,
    CreatedAt:CreatedAt,
    Tags:Tags
  }' \
  --output table


# ------------------------------------------------------------
# CLOUD WAN - CORE NETWORK
# ------------------------------------------------------------

echo
echo "=== CLOUD WAN CORE NETWORK ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws networkmanager describe-core-networks \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'CoreNetworks[*].{
    CoreNetworkId:CoreNetworkId,
    GlobalNetworkId:GlobalNetworkId,
    Description:Description,
    State:State,
    PolicyVersionId:PolicyVersionId,
    Segments:Segments[*].Name
  }' \
  --output table


# ------------------------------------------------------------
# CLOUD WAN - LIVE POLICY
# ------------------------------------------------------------

echo
echo "=== CLOUD WAN LIVE POLICY ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws networkmanager get-core-network-policy \
  --core-network-id "core-network-0f8cd58a4424858dc" \
  --alias LIVE \
  --profile "$PROFILE" \
  --region "$REGION" \
  --output json


# ------------------------------------------------------------
# CLOUD WAN - PEERINGS
# ------------------------------------------------------------

echo
echo "=== CLOUD WAN PEERINGS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws networkmanager list-peerings \
  --core-network-id "core-network-0f8cd58a4424858dc" \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Peerings[*].{
    PeeringId:PeeringId,
    PeeringType:PeeringType,
    State:State,
    EdgeLocation:EdgeLocation,
    ResourceId:TransitGatewayArn,
    OwnerAccountId:OwnerAccountId
  }' \
  --output table


# ------------------------------------------------------------
# CLOUD WAN - ATTACHMENTS
# ------------------------------------------------------------

echo
echo "=== CLOUD WAN ATTACHMENTS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

aws networkmanager list-attachments \
  --core-network-id "core-network-0f8cd58a4424858dc" \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Attachments[*].{
    AttachmentId:AttachmentId,
    Name:Tags[?Key==`Name`]|[0].Value,
    Segment:SegmentName,
    Rule:AttachmentPolicyRuleNumber,
    State:State,
    AttachmentType:AttachmentType,
    ResourceId:ResourceId
  }' \
  --output table


# ------------------------------------------------------------
# CLOUD WAN ATTACHMENT TAGS
# ------------------------------------------------------------

echo
echo "=== CLOUD WAN ATTACHMENT DETAILS ==="
echo "----------------------------------------------------------------------------------------------------------------------"

for ATTACHMENT_ID in \
  "attachment-0057f74cd43f14fb2" \
  "attachment-098bb9559e4c74cc8" \
  "attachment-0b73c14a146af561f" \
  "attachment-0245ded11eebde238"
do

  echo
  echo "Attachment: $ATTACHMENT_ID"

  aws networkmanager get-attachment \
    --attachment-id "$ATTACHMENT_ID" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --output json

done


# ------------------------------------------------------------
# CLOUD WAN NETWORK POLICY / CORE NETWORK SUMMARY
# ------------------------------------------------------------

echo
echo "=== CLOUD WAN SUMMARY ==="
echo "----------------------------------------------------------------------------------------------------------------------"

echo "Global Network:"
echo "  global-network-02fcf44d880601f9"

echo
echo "Core Network:"
echo "  core-network-0f8cd58a4424858dc"

echo
echo "TGW Peering:"
echo "  peering-02aecfac342ab1214"

echo
echo "TGW:"
echo "  tgw-0a8bb2ec2e645f5ad"

echo
echo "Cloud WAN TGW Attachments:"
echo "  Network       : attachment-0057f74cd43f14fb2"
echo "  SharedServices: attachment-098bb9559e4c74cc8"
echo "  Production    : attachment-0b73c14a146af561f"
echo "  NonProduction : attachment-0245ded11eebde238"

echo
echo "=========================================="
echo " DISCOVERY COMPLETE"
echo "=========================================="
echo
