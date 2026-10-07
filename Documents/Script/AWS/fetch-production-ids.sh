#!/bin/bash

set -e

PROFILE="production"
REGION="us-east-1"

echo "=============================================="
echo " Production Network Inventory"
echo "=============================================="
echo

echo "Account"
aws sts get-caller-identity \
  --profile "$PROFILE"

echo
echo "=============================================="
echo " VPCs"
echo "=============================================="

aws ec2 describe-vpcs \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Vpcs[].{
    VPCId:VpcId,
    CIDR:CidrBlock,
    DNSHostnames:EnableDnsHostnames,
    DNSSupport:EnableDnsSupport,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "=============================================="
echo " Subnets"
echo "=============================================="

aws ec2 describe-subnets \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Subnets[].{
    SubnetId:SubnetId,
    VPC:VpcId,
    CIDR:CidrBlock,
    AZ:AvailabilityZone,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "=============================================="
echo " Route Tables"
echo "=============================================="

aws ec2 describe-route-tables \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'RouteTables[].{
    RouteTableId:RouteTableId,
    VPC:VpcId,
    Name:Tags[?Key==`Name`]|[0].Value,
    Routes:Routes
  }' \
  --output json

echo
echo "=============================================="
echo " Internet Gateways"
echo "=============================================="

aws ec2 describe-internet-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'InternetGateways[].{
    IGWId:InternetGatewayId,
    VPCs:Attachments[].VpcId,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "=============================================="
echo " NAT Gateways"
echo "=============================================="

aws ec2 describe-nat-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'NatGateways[].{
    NATGatewayId:NatGatewayId,
    State:State,
    VPC:VpcId,
    Subnet:SubnetId,
    PublicIP:NatGatewayAddresses[0].PublicIp,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "=============================================="
echo " Elastic IPs"
echo "=============================================="

aws ec2 describe-addresses \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Addresses[].{
    AllocationId:AllocationId,
    PublicIP:PublicIp,
    AssociationId:AssociationId,
    InstanceId:InstanceId,
    NATGatewayId:NatGatewayId
  }' \
  --output table

echo
echo "=============================================="
echo " Transit Gateway VPC Attachments"
echo "=============================================="

aws ec2 describe-transit-gateway-vpc-attachments \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'TransitGatewayVpcAttachments[].{
    AttachmentId:TransitGatewayAttachmentId,
    State:State,
    TGW:TransitGatewayId,
    VPC:VpcId,
    Subnets:SubnetIds,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "=============================================="
echo " Transit Gateway"
echo "=============================================="

aws ec2 describe-transit-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'TransitGateways[].{
    TGWId:TransitGatewayId,
    State:State,
    Owner:OwnerId,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "=============================================="
echo " Security Groups"
echo "=============================================="

aws ec2 describe-security-groups \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'SecurityGroups[].{
    GroupId:GroupId,
    Name:GroupName,
    VPC:VpcId,
    Description:Description
  }' \
  --output table

echo
echo "=============================================="
echo " Network ACLs"
echo "=============================================="

aws ec2 describe-network-acls \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'NetworkAcls[].{
    NACLId:NetworkAclId,
    VPC:VpcId,
    Default:IsDefault,
    Associations:Associations
  }' \
  --output json

echo
echo "=============================================="
echo " VPC Endpoints"
echo "=============================================="

aws ec2 describe-vpc-endpoints \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'VpcEndpoints[].{
    EndpointId:VpcEndpointId,
    Type:VpcEndpointType,
    Service:ServiceName,
    VPC:VpcId,
    State:State,
    RouteTables:RouteTableIds,
    Subnets:SubnetIds
  }' \
  --output table

echo
echo "=============================================="
echo " Production Inventory Complete"
echo "=============================================="
