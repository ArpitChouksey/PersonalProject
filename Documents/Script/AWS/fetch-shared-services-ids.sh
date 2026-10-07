#!/bin/bash

PROFILE="sharedservices"
REGION="us-east-1"

echo "======================================================"
echo " SHARED SERVICES AWS RESOURCE INVENTORY"
echo " Profile : $PROFILE"
echo " Region  : $REGION"
echo "======================================================"

echo
echo "### 1. AWS ACCOUNT"
aws sts get-caller-identity \
  --profile "$PROFILE"

echo
echo "### 2. VPC"
aws ec2 describe-vpcs \
  --profile "$PROFILE" \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=*" \
  --query 'Vpcs[*].{
    VPC_ID:VpcId,
    CIDR:CidrBlock,
    State:State,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "### 3. SUBNETS"
aws ec2 describe-subnets \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Subnets[*].{
    Subnet_ID:SubnetId,
    VPC_ID:VpcId,
    AZ:AvailabilityZone,
    CIDR:CidrBlock,
    State:State,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "### 4. ROUTE TABLES"
aws ec2 describe-route-tables \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'RouteTables[*].{
    RouteTable_ID:RouteTableId,
    VPC_ID:VpcId,
    Name:Tags[?Key==`Name`]|[0].Value,
    Associations:Associations[*].SubnetId,
    Routes:Routes[*].{Destination:DestinationCidrBlock,Gateway:GatewayId,TGW:TransitGatewayId}
  }' \
  --output json

echo
echo "### 5. INTERNET GATEWAYS"
aws ec2 describe-internet-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'InternetGateways[*].{
    IGW_ID:InternetGatewayId,
    VPCs:Attachments[*].VpcId,
    State:Attachments[*].State,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "### 6. NAT GATEWAYS"
aws ec2 describe-nat-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'NatGateways[*].{
    NAT_ID:NatGatewayId,
    VPC_ID:VpcId,
    Subnet_ID:SubnetId,
    State:State,
    EIP:NatGatewayAddresses[*].PublicIp,
    Allocation_ID:NatGatewayAddresses[*].AllocationId,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "### 7. ELASTIC IPs"
aws ec2 describe-addresses \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Addresses[*].{
    Allocation_ID:AllocationId,
    Public_IP:PublicIp,
    Private_IP:PrivateIpAddress,
    Association_ID:AssociationId,
    Instance_ID:InstanceId,
    NetworkInterface_ID:NetworkInterfaceId,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "### 8. TRANSIT GATEWAY ATTACHMENTS"
aws ec2 describe-transit-gateway-vpc-attachments \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'TransitGatewayVpcAttachments[*].{
    Attachment_ID:TransitGatewayAttachmentId,
    TGW_ID:TransitGatewayId,
    VPC_ID:VpcId,
    State:State,
    Owner:TransitGatewayOwnerId,
    ResourceOwner:ResourceOwnerId,
    Name:Tags[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "### 9. NETWORK INTERFACES"
aws ec2 describe-network-interfaces \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'NetworkInterfaces[*].{
    ENI_ID:NetworkInterfaceId,
    VPC_ID:VpcId,
    Subnet_ID:SubnetId,
    Private_IP:PrivateIpAddress,
    Status:Status,
    Description:Description,
    Type:InterfaceType,
    Name:TagSet[?Key==`Name`]|[0].Value
  }' \
  --output table

echo
echo "### 10. SECURITY GROUPS"
aws ec2 describe-security-groups \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'SecurityGroups[*].{
    SG_ID:GroupId,
    Name:GroupName,
    VPC_ID:VpcId,
    Description:Description
  }' \
  --output table

echo
echo "### 11. NETWORK ACLs"
aws ec2 describe-network-acls \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'NetworkAcls[*].{
    NACL_ID:NetworkAclId,
    VPC_ID:VpcId,
    Default:IsDefault,
    Associations:Associations[*].SubnetId
  }' \
  --output json

echo
echo "### 12. VPC ENDPOINTS"
aws ec2 describe-vpc-endpoints \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'VpcEndpoints[*].{
    Endpoint_ID:VpcEndpointId,
    VPC_ID:VpcId,
    Type:VpcEndpointType,
    Service:ServiceName,
    State:State,
    RouteTables:RouteTableIds
  }' \
  --output table

echo
echo "======================================================"
echo " INVENTORY COMPLETE"
echo "======================================================"
