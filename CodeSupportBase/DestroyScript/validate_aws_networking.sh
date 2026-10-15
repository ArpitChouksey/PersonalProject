#!/usr/bin/env bash
set -u

REGION="us-east-1"
VPC="vpc-074db46afdba5d9c6"
EXPECTED_ACCOUNT="211811255273"

echo "=================================================="
echo " AWS NETWORKING RESOURCE VALIDATION"
echo "=================================================="

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: AWS CLI is not installed."
  exit 1
fi

ACCOUNT=$(aws sts get-caller-identity \
  --query Account --output text 2>/dev/null) || {
    echo "ERROR: AWS credentials are invalid."
    exit 1
  }

echo "Account: $ACCOUNT"
echo "Region:  $REGION"
echo "VPC:     $VPC"

if [[ "$ACCOUNT" != "$EXPECTED_ACCOUNT" ]]; then
  echo "ERROR: Wrong account. Expected $EXPECTED_ACCOUNT."
  exit 1
fi

run_check() {
  echo
  echo "========== $1 =========="
  shift
  "$@" || echo "WARNING: Check failed; verify permissions or resource state."
}

run_check "VPC" \
  aws ec2 describe-vpcs --region "$REGION" \
  --vpc-ids "$VPC" \
  --query 'Vpcs[].{VpcId:VpcId,State:State,CIDR:CidrBlock}' \
  --output table

run_check "SUBNETS" \
  aws ec2 describe-subnets --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'Subnets[].{Subnet:SubnetId,State:State,CIDR:CidrBlock,AZ:AvailabilityZone}' \
  --output table

run_check "EC2 INSTANCES" \
  aws ec2 describe-instances --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'Reservations[].Instances[].{Instance:InstanceId,State:State.Name,Subnet:SubnetId,PublicIP:PublicIpAddress}' \
  --output table

run_check "RDS DATABASES" \
  aws rds describe-db-instances --region "$REGION" \
  --query "DBInstances[?DBSubnetGroup.VpcId=='$VPC'].{DB:DBInstanceIdentifier,Status:DBInstanceStatus,VPC:DBSubnetGroup.VpcId}" \
  --output table

run_check "NETWORK INTERFACES" \
  aws ec2 describe-network-interfaces --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'NetworkInterfaces[].{ENI:NetworkInterfaceId,Status:Status,Type:InterfaceType,Description:Description,Subnet:SubnetId,Managed:RequesterManaged,PublicIP:Association.PublicIp}' \
  --output table

run_check "INTERNET GATEWAYS" \
  aws ec2 describe-internet-gateways --region "$REGION" \
  --filters "Name=attachment.vpc-id,Values=$VPC" \
  --query 'InternetGateways[].{IGW:InternetGatewayId,Attachments:Attachments}' \
  --output table

run_check "NAT GATEWAYS" \
  aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=vpc-id,Values=$VPC" \
  --query 'NatGateways[].{NAT:NatGatewayId,State:State,Subnet:SubnetId}' \
  --output table

run_check "VPC ENDPOINTS" \
  aws ec2 describe-vpc-endpoints --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'VpcEndpoints[].{Endpoint:VpcEndpointId,State:State,Type:VpcEndpointType,Service:ServiceName}' \
  --output table

run_check "CLIENT VPN ENDPOINTS" \
  aws ec2 describe-client-vpn-endpoints --region "$REGION" \
  --query 'ClientVpnEndpoints[].{Endpoint:ClientVpnEndpointId,State:Status.Code,Description:Description}' \
  --output table

run_check "SITE-TO-SITE VPN CONNECTIONS" \
  aws ec2 describe-vpn-connections --region "$REGION" \
  --query 'VpnConnections[].{VPN:VpnConnectionId,State:State,VGW:VpnGatewayId,CustomerGateway:CustomerGatewayId,TransitGateway:TransitGatewayId}' \
  --output table

run_check "CUSTOMER GATEWAYS" \
  aws ec2 describe-customer-gateways --region "$REGION" \
  --query 'CustomerGateways[].{Gateway:CustomerGatewayId,State:State,IP:IpAddress}' \
  --output table

run_check "VIRTUAL PRIVATE GATEWAYS" \
  aws ec2 describe-vpn-gateways --region "$REGION" \
  --query 'VpnGateways[].{Gateway:VpnGatewayId,State:State,Attachments:VpcAttachments}' \
  --output table

run_check "TRANSIT GATEWAY ATTACHMENTS" \
  aws ec2 describe-transit-gateway-vpc-attachments --region "$REGION" \
  --query "TransitGatewayVpcAttachments[?VpcId=='$VPC'].{Attachment:TransitGatewayAttachmentId,State:State,TGW:TransitGatewayId}" \
  --output table

run_check "VPC PEERING" \
  aws ec2 describe-vpc-peering-connections --region "$REGION" \
  --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='$VPC' || AccepterVpcInfo.VpcId=='$VPC'].{Peering:VpcPeeringConnectionId,State:Status.Code}" \
  --output table

run_check "ELASTIC IP ADDRESSES" \
  aws ec2 describe-addresses --region "$REGION" \
  --query 'Addresses[].{Allocation:AllocationId,IP:PublicIp,Association:AssociationId,ENI:NetworkInterfaceId,Instance:InstanceId}' \
  --output table

run_check "LOAD BALANCERS" \
  aws elbv2 describe-load-balancers --region "$REGION" \
  --query "LoadBalancers[?VpcId=='$VPC'].{Name:LoadBalancerName,Type:Type,State:State.Code}" \
  --output table

run_check "ROUTE TABLES" \
  aws ec2 describe-route-tables --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'RouteTables[].{RouteTable:RouteTableId,Associations:Associations,Routes:Routes}' \
  --output json

run_check "SECURITY GROUPS" \
  aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'SecurityGroups[].{Group:GroupId,Name:GroupName}' \
  --output table

run_check "NETWORK ACLS" \
  aws ec2 describe-network-acls --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'NetworkAcls[].{ACL:NetworkAclId,Default:IsDefault,SubnetAssociations:Associations}' \
  --output table

echo
echo "=================================================="
echo " VALIDATION FINISHED"
echo "=================================================="
echo "Empty results mean no matching resources were returned."
echo "Check errors, permissions, and resource state before concluding cleanup."
echo "This validates the target VPC and selected regional resources only."
