#!/usr/bin/env bash
set -Eeuo pipefail

REGION="us-east-1"
ACCOUNT_EXPECTED="211811255273"
VPC="vpc-074db46afdba5d9c6"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
[[ "$ACCOUNT" == "$ACCOUNT_EXPECTED" ]] || {
  echo "Wrong AWS account: $ACCOUNT"
  exit 1
}

echo "Account: $ACCOUNT"
echo "Region: $REGION"
echo "Target VPC: $VPC"
echo
echo "This deletes remaining custom networking resources in the target VPC."
read -r -p "Type DELETE-$VPC to continue: " CONFIRM
[[ "$CONFIRM" == "DELETE-$VPC" ]] || {
  echo "Cancelled."
  exit 1
}

echo "=== Check for remaining network interfaces ==="
aws ec2 describe-network-interfaces --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'NetworkInterfaces[].{ENI:NetworkInterfaceId,Status:Status,Description:Description,RequesterManaged:RequesterManaged}' \
  --output table

ENI_COUNT=$(aws ec2 describe-network-interfaces --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'length(NetworkInterfaces)' --output text)

if [[ "$ENI_COUNT" != "0" ]]; then
  echo "ENIs remain. They must be released by their owning service before VPC deletion."
  echo "No ENIs will be force-deleted. Resolve the listed dependencies first."
  exit 1
fi

echo "=== Delete custom security groups ==="
for SG in $(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" \
  --output text); do
  echo "Deleting $SG"
  aws ec2 delete-security-group --region "$REGION" --group-id "$SG"
done

echo "=== Delete non-default network ACLs ==="
for ACL in $(aws ec2 describe-network-acls --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' \
  --output text); do
  aws ec2 delete-network-acl --region "$REGION" --network-acl-id "$ACL"
done

echo "=== Delete non-main route tables ==="
for RTB in $(aws ec2 describe-route-tables --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query "RouteTables[?Associations[?Main!=\`true\`]].RouteTableId" \
  --output text); do
  for ASSOC in $(aws ec2 describe-route-tables --region "$REGION" \
    --route-table-ids "$RTB" \
    --query "RouteTables[].Associations[?Main!=\`true\`].RouteTableAssociationId" \
    --output text); do
    [[ -z "$ASSOC" || "$ASSOC" == "None" ]] && continue
    aws ec2 disassociate-route-table --region "$REGION" \
      --association-id "$ASSOC"
  done
  aws ec2 delete-route-table --region "$REGION" --route-table-id "$RTB"
done

echo "=== Delete remaining subnets ==="
for SUBNET in $(aws ec2 describe-subnets --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'Subnets[].SubnetId' --output text); do
  aws ec2 delete-subnet --region "$REGION" --subnet-id "$SUBNET"
done

echo "=== Delete VPC ==="
aws ec2 delete-vpc --region "$REGION" --vpc-id "$VPC"

echo
echo "=== Final verification ==="
if aws ec2 describe-vpcs --region "$REGION" --vpc-ids "$VPC" >/dev/null 2>&1; then
  echo "WARNING: VPC still exists. Inspect the dependency error."
else
  echo "SUCCESS: Target VPC no longer exists."
fi
