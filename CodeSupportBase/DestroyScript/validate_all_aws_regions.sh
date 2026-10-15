#!/bin/bash
set -u

EXPECTED_ACCOUNT="211811255273"
OUT="aws_validation_$(date +%Y%m%d_%H%M%S).txt"

# ============================================================
# 1. Verify AWS identity
# ============================================================
echo "Checking AWS identity..."

IDENTITY=$(aws sts get-caller-identity --output json 2>&1) || {
  echo "ERROR: Unable to verify AWS identity."
  echo "$IDENTITY"
  exit 1
}

ACCOUNT=$(printf '%s' "$IDENTITY" | python3 -c \
  'import json,sys; print(json.load(sys.stdin)["Account"])')
CALLER=$(printf '%s' "$IDENTITY" | python3 -c \
  'import json,sys; print(json.load(sys.stdin)["Arn"])')

if [ "$ACCOUNT" != "$EXPECTED_ACCOUNT" ]; then
  echo "ERROR: Wrong AWS account."
  echo "Expected: $EXPECTED_ACCOUNT"
  echo "Current:  $ACCOUNT"
  exit 1
fi

echo "Account: $ACCOUNT"
echo "Caller:  $CALLER"
echo "Report:  $OUT"

# ============================================================
# 2. Get all enabled AWS regions
# Compatible with macOS default Bash 3.2 (no mapfile)
# ============================================================
REGIONS_TEXT=$(aws ec2 describe-regions \
  --region us-east-1 \
  --all-regions \
  --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].RegionName" \
  --output text 2>&1) || {
    echo "ERROR: Unable to retrieve AWS regions."
    echo "$REGIONS_TEXT"
    exit 1
  }

REGIONS=$(printf '%s\n' "$REGIONS_TEXT" | tr '\t' '\n' | sort)

if [ -z "$REGIONS" ] || [ "$REGIONS" = "None" ]; then
  echo "ERROR: No enabled regions returned."
  exit 1
fi

# ============================================================
# 3. Initialize report
# ============================================================
{
  echo "AWS ALL-REGIONS RESOURCE VALIDATION"
  echo "Account: $ACCOUNT"
  echo "Caller: $CALLER"
  echo "Date: $(date)"
  echo "Read-only inventory; no resources will be modified."
  echo "=============================================="
} | tee "$OUT"

# ============================================================
# Helper: run a check and capture failures
# ============================================================
scan() {
  LABEL="$1"
  shift

  echo "--- $LABEL ---" | tee -a "$OUT"

  RESULT=$("$@" 2>&1)
  RC=$?

  if [ "$RC" -ne 0 ]; then
    echo "CHECK ERROR (exit $RC): $RESULT" | tee -a "$OUT"
  elif [ -z "$RESULT" ] || [ "$RESULT" = "None" ]; then
    echo "No resources found." | tee -a "$OUT"
  else
    printf '%s\n' "$RESULT" | tee -a "$OUT"
  fi

  echo | tee -a "$OUT"
}

# ============================================================
# 4. Scan every enabled region
# ============================================================
REGION_COUNT=0

for REGION in $REGIONS; do
  REGION_COUNT=$((REGION_COUNT + 1))

  echo
  echo "==============================================" | tee -a "$OUT"
  echo "REGION: $REGION" | tee -a "$OUT"
  echo "==============================================" | tee -a "$OUT"

  # ---------------- VPC networking ----------------
  scan "VPCs" \
    aws ec2 describe-vpcs --region "$REGION" \
    --query 'Vpcs[].{VPC:VpcId,CIDR:CidrBlock,State:State,Default:IsDefault}' \
    --output table

  scan "Subnets" \
    aws ec2 describe-subnets --region "$REGION" \
    --query 'Subnets[].{Subnet:SubnetId,VPC:VpcId,CIDR:CidrBlock,AZ:AvailabilityZone}' \
    --output table

  scan "Internet gateways" \
    aws ec2 describe-internet-gateways --region "$REGION" \
    --query 'InternetGateways[].{IGW:InternetGatewayId,Attachments:Attachments}' \
    --output json

  scan "NAT gateways (active or transitional)" \
    aws ec2 describe-nat-gateways --region "$REGION" \
    --filter Name=state,Values=pending,available,failed,deleting \
    --query 'NatGateways[].{NAT:NatGatewayId,VPC:VpcId,State:State,Subnet:SubnetId}' \
    --output table

  scan "VPC endpoints" \
    aws ec2 describe-vpc-endpoints --region "$REGION" \
    --query 'VpcEndpoints[].{Endpoint:VpcEndpointId,VPC:VpcId,Type:VpcEndpointType,State:State,Service:ServiceName}' \
    --output table

  scan "Route tables" \
    aws ec2 describe-route-tables --region "$REGION" \
    --query 'RouteTables[].{RouteTable:RouteTableId,VPC:VpcId,Associations:Associations[].SubnetId}' \
    --output json

  scan "Security groups" \
    aws ec2 describe-security-groups --region "$REGION" \
    --query 'SecurityGroups[].{Group:GroupId,Name:GroupName,VPC:VpcId}' \
    --output table

  scan "Network ACLs" \
    aws ec2 describe-network-acls --region "$REGION" \
    --query 'NetworkAcls[].{ACL:NetworkAclId,VPC:VpcId,Default:IsDefault}' \
    --output table

  scan "Network interfaces" \
    aws ec2 describe-network-interfaces --region "$REGION" \
    --query 'NetworkInterfaces[].{ENI:NetworkInterfaceId,VPC:VpcId,Subnet:SubnetId,Status:Status,Description:Description,Managed:RequesterManaged}' \
    --output table

  scan "VPC flow logs" \
    aws ec2 describe-flow-logs --region "$REGION" \
    --query 'FlowLogs[].{FlowLog:FlowLogId,Resource:ResourceId,Status:FlowLogStatus,Destination:LogDestination}' \
    --output table

  # ---------------- VPN and connectivity ----------------
  scan "Client VPN endpoints" \
    aws ec2 describe-client-vpn-endpoints --region "$REGION" \
    --query 'ClientVpnEndpoints[].{Endpoint:ClientVpnEndpointId,Status:Status.Code,Description:Description}' \
    --output table

  scan "Site-to-Site VPN connections" \
    aws ec2 describe-vpn-connections --region "$REGION" \
    --query 'VpnConnections[].{VPN:VpnConnectionId,State:State,VGW:VpnGatewayId,CGW:CustomerGatewayId,Type:Type}' \
    --output table

  scan "Customer gateways" \
    aws ec2 describe-customer-gateways --region "$REGION" \
    --query 'CustomerGateways[].{CGW:CustomerGatewayId,State:State,IP:IpAddress,BGPASN:BgpAsn}' \
    --output table

  scan "Virtual private gateways" \
    aws ec2 describe-vpn-gateways --region "$REGION" \
    --query 'VpnGateways[].{VGW:VpnGatewayId,State:State,Attachments:VpcAttachments}' \
    --output json

  scan "Transit gateways" \
    aws ec2 describe-transit-gateways --region "$REGION" \
    --query 'TransitGateways[].{TGW:TransitGatewayId,State:State,Owner:OwnerId}' \
    --output table

  scan "Transit gateway attachments" \
    aws ec2 describe-transit-gateway-attachments --region "$REGION" \
    --query 'TransitGatewayAttachments[].{Attachment:TransitGatewayAttachmentId,Type:ResourceType,Resource:ResourceId,State:State}' \
    --output table

  scan "VPC peering connections" \
    aws ec2 describe-vpc-peering-connections --region "$REGION" \
    --query 'VpcPeeringConnections[].{Peering:VpcPeeringConnectionId,Status:Status.Code,Requester:RequesterVpcInfo.VpcId,Accepter:AccepterVpcInfo.VpcId}' \
    --output table

  scan "Elastic IP addresses" \
    aws ec2 describe-addresses --region "$REGION" \
    --query 'Addresses[].{Allocation:AllocationId,IP:PublicIp,Association:AssociationId,Instance:InstanceId,ENI:NetworkInterfaceId}' \
    --output table

  # ---------------- Compute and databases ----------------
  scan "EC2 instances (all states)" \
    aws ec2 describe-instances --region "$REGION" \
    --query 'Reservations[].Instances[].{Instance:InstanceId,State:State.Name,VPC:VpcId,Subnet:SubnetId,PublicIP:PublicIpAddress}' \
    --output table

  scan "RDS databases" \
    aws rds describe-db-instances --region "$REGION" \
    --query 'DBInstances[].{DB:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine,VPC:DBSubnetGroup.VpcId}' \
    --output table

  scan "RDS DB subnet groups" \
    aws rds describe-db-subnet-groups --region "$REGION" \
    --query 'DBSubnetGroups[].{Name:DBSubnetGroupName,VPC:VpcId,Status:SubnetGroupStatus}' \
    --output table

  # ---------------- Load balancing ----------------
  scan "ELBv2 load balancers" \
    aws elbv2 describe-load-balancers --region "$REGION" \
    --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,State:State.Code,VPC:VpcId,DNS:DNSName}' \
    --output table

  scan "Classic load balancers" \
    aws elb describe-load-balancers --region "$REGION" \
    --query 'LoadBalancerDescriptions[].{Name:LoadBalancerName,VPC:VPCId,DNS:DNSName}' \
    --output table

  # ---------------- Other networking services ----------------
  scan "Network Firewall firewalls" \
    aws network-firewall list-firewalls --region "$REGION" \
    --query 'Firewalls[].{Name:FirewallName,ARN:FirewallArn,VPC:VpcId}' \
    --output table

  scan "EKS clusters" \
    aws eks list-clusters --region "$REGION" \
    --output table

  scan "ECS clusters" \
    aws ecs list-clusters --region "$REGION" \
    --output table

done

# ============================================================
# 5. Final summary
# ============================================================
{
  echo
  echo "=============================================="
  echo "VALIDATION COMPLETE"
  echo "Account: $ACCOUNT"
  echo "Enabled regions scanned: $REGION_COUNT"
  echo "Report saved to: $OUT"
  echo "=============================================="
} | tee -a "$OUT"

echo
echo "To review the report:"
echo "  less \"$OUT\""
echo
echo "To find the lab VPC and related resource IDs:"
echo "  grep -nE 'vpc-074db46afdba5d9c6|vpn-|cvpn-|cgw-|vgw-|eni-|nat-|vpce-' \"$OUT\""
