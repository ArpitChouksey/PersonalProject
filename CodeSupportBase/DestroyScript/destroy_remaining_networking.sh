#!/usr/bin/env bash
set -Eeuo pipefail

REGION="us-east-1"
ACCOUNT_EXPECTED="211811255273"
VPC="vpc-074db46afdba5d9c6"
INSTANCE="i-0c51672deaacf0e68"
DB="database-1"
IGW="igw-0bf931f2a1d12156b"
VGW="vgw-025a213a4e8c84256"
CGW="cgw-038acc8620e87150a"
VPN="vpn-0f86a64ca5e2f9218"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
[[ "$ACCOUNT" == "$ACCOUNT_EXPECTED" ]] || {
  echo "Wrong AWS account: $ACCOUNT"; exit 1;
}

echo "Account: $ACCOUNT"
echo "Region: $REGION"
echo "Target VPC: $VPC"
echo "This permanently terminates the EC2 instance and deletes the RDS database."
read -r -p "Type DELETE-$VPC to continue: " CONFIRM
[[ "$CONFIRM" == "DELETE-$VPC" ]] || { echo "Cancelled"; exit 1; }

echo "=== Delete RDS if it still exists ==="
if aws rds describe-db-instances --region "$REGION" \
  --db-instance-identifier "$DB" >/dev/null 2>&1; then
  STATUS=$(aws rds describe-db-instances --region "$REGION" \
    --db-instance-identifier "$DB" \
    --query 'DBInstances[0].DBInstanceStatus' --output text)
  if [[ "$STATUS" != "deleting" ]]; then
    aws rds delete-db-instance --region "$REGION" \
      --db-instance-identifier "$DB" \
      --skip-final-snapshot --delete-automated-backups
  fi
  echo "Waiting for RDS deletion..."
  aws rds wait db-instance-deleted --region "$REGION" \
    --db-instance-identifier "$DB"
fi

echo "=== Terminate EC2 ==="
STATE=$(aws ec2 describe-instances --region "$REGION" \
  --instance-ids "$INSTANCE" \
  --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo absent)
if [[ "$STATE" != "absent" && "$STATE" != "terminated" ]]; then
  aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE"
  aws ec2 wait instance-terminated --region "$REGION" --instance-ids "$INSTANCE"
fi

echo "=== Delete Site-to-Site VPN if still present ==="
aws ec2 delete-vpn-connection --region "$REGION" \
  --vpn-connection-id "$VPN" 2>/dev/null || true

echo "=== Delete detached Virtual Private Gateway ==="
aws ec2 detach-vpn-gateway --region "$REGION" \
  --vpn-gateway-id "$VGW" --vpc-id "$VPC" 2>/dev/null || true
for i in {1..12}; do
  ATTACH=$(aws ec2 describe-vpn-gateways --region "$REGION" \
    --vpn-gateway-ids "$VGW" \
    --query 'VpnGateways[0].VpcAttachments[0].State' --output text 2>/dev/null || echo absent)
  [[ "$ATTACH" == "detached" || "$ATTACH" == "None" || "$ATTACH" == "absent" ]] && break
  sleep 10
done
aws ec2 delete-vpn-gateway --region "$REGION" \
  --vpn-gateway-id "$VGW" 2>/dev/null || true

echo "=== Delete customer gateway if no VPN connection references it ==="
USED=$(aws ec2 describe-vpn-connections --region "$REGION" \
  --filters "Name=customer-gateway-id,Values=$CGW" \
  --query 'length(VpnConnections[?State!=`deleted`])' --output text)
if [[ "$USED" == "0" ]]; then
  aws ec2 delete-customer-gateway --region "$REGION" \
    --customer-gateway-id "$CGW" 2>/dev/null || true
else
  echo "Customer gateway still referenced by a VPN; leaving it in place."
fi

echo "=== Remove VPC endpoints ==="
for id in $(aws ec2 describe-vpc-endpoints --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'VpcEndpoints[].VpcEndpointId' --output text); do
  aws ec2 delete-vpc-endpoints --region "$REGION" --vpc-endpoint-ids "$id" || true
done

echo "=== Remove NAT gateways ==="
for id in $(aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=vpc-id,Values=$VPC" \
  --query "NatGateways[?State!='deleted'].NatGatewayId" --output text); do
  aws ec2 delete-nat-gateway --region "$REGION" --nat-gateway-id "$id" || true
done

echo "=== Wait for ENIs and public IP associations to clear ==="
for i in {1..12}; do
  COUNT=$(aws ec2 describe-network-interfaces --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC" \
    --query 'length(NetworkInterfaces[?RequesterManaged==`false`])' --output text)
  [[ "$COUNT" == "0" ]] && break
  echo "Waiting for remaining customer-managed ENIs ($COUNT)..."
  sleep 10
done

echo "=== Detach and delete Internet Gateway ==="
aws ec2 detach-internet-gateway --region "$REGION" \
  --internet-gateway-id "$IGW" --vpc-id "$VPC" || true
aws ec2 delete-internet-gateway --region "$REGION" \
  --internet-gateway-id "$IGW" || true

echo "=== Delete subnets ==="
for subnet in $(aws ec2 describe-subnets --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'Subnets[].SubnetId' --output text); do
  aws ec2 delete-subnet --region "$REGION" --subnet-id "$subnet" || true
done

echo "=== Delete non-default security groups ==="
for sg in $(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
  aws ec2 delete-security-group --region "$REGION" --group-id "$sg" || true
done

echo "=== Delete VPC ==="
aws ec2 delete-vpc --region "$REGION" --vpc-id "$VPC" || true

echo "=== Final status ==="
aws ec2 describe-vpcs --region "$REGION" --vpc-ids "$VPC" \
  --query 'Vpcs[].{Vpc:VpcId,State:State}' --output table 2>/dev/null || \
  echo "VPC no longer exists."

echo
echo "Cleanup attempt finished. Review errors and rerun the validation script."
echo "This does not delete shared Transit Gateway/Cloud WAN resources or unrelated VPCs."
