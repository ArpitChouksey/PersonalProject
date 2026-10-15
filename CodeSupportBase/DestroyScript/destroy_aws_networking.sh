#!/usr/bin/env bash
set -Eeuo pipefail

ACCOUNT="211811255273"
REGION="us-east-1"
VPC="vpc-074db46afdba5d9c6"

die() { echo "ERROR: $*" >&2; exit 1; }

command -v aws >/dev/null || die "AWS CLI is required."

ACTUAL_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
[[ "$ACTUAL_ACCOUNT" == "$ACCOUNT" ]] ||
  die "Wrong account: expected $ACCOUNT, got $ACTUAL_ACCOUNT"

aws ec2 describe-vpcs --region "$REGION" --vpc-ids "$VPC" >/dev/null ||
  die "Target VPC not found in $REGION."

echo "Account: $ACCOUNT"
echo "Region:  $REGION"
echo "Target:  $VPC"
echo
echo "=== VPC and networking inventory ==="

aws ec2 describe-vpcs --region "$REGION" --vpc-ids "$VPC" \
  --query 'Vpcs[].{VpcId:VpcId,CIDR:CidrBlock,State:State}' --output table

aws ec2 describe-subnets --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'Subnets[].{SubnetId:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone}' \
  --output table

aws ec2 describe-internet-gateways --region "$REGION" \
  --filters "Name=attachment.vpc-id,Values=$VPC" \
  --query 'InternetGateways[].InternetGatewayId' --output table

aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=vpc-id,Values=$VPC" \
  --query 'NatGateways[].{NatGatewayId:NatGatewayId,State:State}' --output table

aws ec2 describe-vpc-endpoints --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'VpcEndpoints[].{Id:VpcEndpointId,Type:VpcEndpointType,State:State}' \
  --output table

aws ec2 describe-client-vpn-endpoints --region "$REGION" \
  --query 'ClientVpnEndpoints[].{Id:ClientVpnEndpointId,Status:Status.Code,Description:Description}' \
  --output table

echo
echo "=== VPN inventory ==="
aws ec2 describe-vpn-connections --region "$REGION" \
  --query 'VpnConnections[].{VpnId:VpnConnectionId,Gateway:VpnGatewayId,State:State,CustomerGateway:CustomerGatewayId}' \
  --output table

aws ec2 describe-customer-gateways --region "$REGION" \
  --query 'CustomerGateways[].{Id:CustomerGatewayId,State:State,IP:IpAddress}' \
  --output table

aws ec2 describe-vpn-gateways --region "$REGION" \
  --query 'VpnGateways[].{Id:VpnGatewayId,State:State,Type:Type}' \
  --output table

echo
echo "This script will delete the target VPC and related resources."
echo "VPN resources not linked to the target VPC will be left alone."
read -r -p "Type DELETE-$VPC to continue: " CONFIRM
[[ "$CONFIRM" == "DELETE-$VPC" ]] || die "Cancelled."

# 1. Delete Client VPN endpoints associated with the target VPC.
for endpoint in $(aws ec2 describe-client-vpn-endpoints --region "$REGION" \
  --query 'ClientVpnEndpoints[].ClientVpnEndpointId' --output text); do
  associations=$(aws ec2 describe-client-vpn-target-networks --region "$REGION" \
    --client-vpn-endpoint-id "$endpoint" \
    --query "ClientVpnTargetNetworks[?VpcId=='$VPC'].AssociationId" --output text)
  if [[ -n "$associations" && "$associations" != "None" ]]; then
    echo "Disassociating Client VPN $endpoint from $VPC"
    for assoc in $associations; do
      aws ec2 disassociate-client-vpn-target-network --region "$REGION" \
        --client-vpn-endpoint-id "$endpoint" --association-id "$assoc" || true
    done
    aws ec2 delete-client-vpn-endpoint --region "$REGION" \
      --client-vpn-endpoint-id "$endpoint" || true
  fi
done

# 2. Delete VPC endpoints.
for id in $(aws ec2 describe-vpc-endpoints --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'VpcEndpoints[].VpcEndpointId' --output text); do
  echo "Deleting VPC endpoint $id"
  aws ec2 delete-vpc-endpoints --region "$REGION" --vpc-endpoint-ids "$id" || true
done

# 3. Delete NAT gateways and wait until removed.
for id in $(aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=vpc-id,Values=$VPC" \
  --query "NatGateways[?State!='deleted'].NatGatewayId" --output text); do
  echo "Deleting NAT gateway $id"
  aws ec2 delete-nat-gateway --region "$REGION" --nat-gateway-id "$id" || true
done

# 4. Delete VPC peering connections involving this VPC.
for id in $(aws ec2 describe-vpc-peering-connections --region "$REGION" \
  --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='$VPC' || AccepterVpcInfo.VpcId=='$VPC'].VpcPeeringConnectionId" \
  --output text); do
  echo "Deleting VPC peering $id"
  aws ec2 delete-vpc-peering-connection --region "$REGION" \
    --vpc-peering-connection-id "$id" || true
done

# 5. Delete Site-to-Site VPN connections attached to a VGW associated with this VPC.
for vgw in $(aws ec2 describe-vpn-gateways --region "$REGION" \
  --filters "Name=attachment.vpc-id,Values=$VPC" \
  --query 'VpnGateways[].VpnGatewayId' --output text); do

  for vpn in $(aws ec2 describe-vpn-connections --region "$REGION" \
    --filters "Name=vpn-gateway-id,Values=$vgw" \
    --query 'VpnConnections[].VpnConnectionId' --output text); do
    echo "Deleting VPN connection $vpn"
    aws ec2 delete-vpn-connection --region "$REGION" \
      --vpn-connection-id "$vpn" || true
  done

  echo "Detaching VGW $vgw from $VPC"
  aws ec2 detach-vpn-gateway --region "$REGION" \
    --vpn-gateway-id "$vgw" --vpc-id "$VPC" || true

  echo "Deleting VGW $vgw"
  aws ec2 delete-vpn-gateway --region "$REGION" \
    --vpn-gateway-id "$vgw" || true
done

# 6. Delete customer gateways only if no VPN connections reference them.
for cgw in $(aws ec2 describe-customer-gateways --region "$REGION" \
  --query 'CustomerGateways[].CustomerGatewayId' --output text); do
  used=$(aws ec2 describe-vpn-connections --region "$REGION" \
    --filters "Name=customer-gateway-id,Values=$cgw" \
    --query 'length(VpnConnections)' --output text)
  if [[ "$used" == "0" ]]; then
    echo "Deleting unused customer gateway $cgw"
    aws ec2 delete-customer-gateway --region "$REGION" \
      --customer-gateway-id "$cgw" || true
  fi
done

# 7. Delete NAT gateways may still be processing; wait briefly for state changes.
echo "Waiting for NAT gateways to finish deleting..."
sleep 15

# 8. Delete attached internet gateways.
for igw in $(aws ec2 describe-internet-gateways --region "$REGION" \
  --filters "Name=attachment.vpc-id,Values=$VPC" \
  --query 'InternetGateways[].InternetGatewayId' --output text); do
  aws ec2 detach-internet-gateway --region "$REGION" \
    --internet-gateway-id "$igw" --vpc-id "$VPC" || true
  aws ec2 delete-internet-gateway --region "$REGION" \
    --internet-gateway-id "$igw" || true
done

# 9. Remove non-main route tables; main route table is removed with the VPC.
for rtb in $(aws ec2 describe-route-tables --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query "RouteTables[?Associations[?Main!=\`true\`]].RouteTableId" \
  --output text); do
  aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$rtb" \
    --query 'RouteTables[].Associations[?Main!=`true`].RouteTableAssociationId' \
    --output text | tr '\t' '\n' | while read -r assoc; do
      [[ -z "$assoc" || "$assoc" == "None" ]] && continue
      aws ec2 disassociate-route-table --region "$REGION" \
        --association-id "$assoc" || true
    done
  aws ec2 delete-route-table --region "$REGION" --route-table-id "$rtb" || true
done

# 10. Delete subnets after dependent resources have been removed.
for subnet in $(aws ec2 describe-subnets --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'Subnets[].SubnetId' --output text); do
  echo "Deleting subnet $subnet"
  aws ec2 delete-subnet --region "$REGION" --subnet-id "$subnet" || true
done

# 11. Delete non-default security groups and network ACLs.
for sg in $(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
  aws ec2 delete-security-group --region "$REGION" --group-id "$sg" || true
done

for acl in $(aws ec2 describe-network-acls --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query "NetworkAcls[?IsDefault==\`false\`].NetworkAclId" --output text); do
  aws ec2 delete-network-acl --region "$REGION" --network-acl-id "$acl" || true
done

# 12. Delete the VPC. This fails safely if resources remain.
echo "Attempting to delete VPC $VPC"
aws ec2 delete-vpc --region "$REGION" --vpc-id "$VPC" ||
  echo "VPC deletion failed; inspect remaining dependencies below."

echo
echo "=== FINAL CHECK ==="
aws ec2 describe-vpcs --region "$REGION" --vpc-ids "$VPC" \
  --query 'Vpcs[].{VpcId:VpcId,State:State}' --output table 2>/dev/null ||
  echo "Target VPC no longer exists."

echo
echo "Cleanup attempted. Review any errors above and inspect the AWS Console."
echo "This script does not delete EC2/RDS, Transit Gateways, Cloud WAN, or unrelated VPN resources."
