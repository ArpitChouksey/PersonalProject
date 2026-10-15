
#!/usr/bin/env bash
set -Eeuo pipefail

# AWS migration lab cleanup — us-east-1
# Requires: AWS CLI v2, jq, and credentials with deletion permissions.

REGION="us-east-1"
EXPECTED_ACCOUNT="211811255273"
VPC_ID="vpc-02e169f095c5f6634"
EC2_ID="i-03e267afe7cf7b4d4"
RDS_ID="rds-migration-pilot"
VGW_ID="vgw-0ada02dcc4f21800b"
ROLE_NAME="role-aws-migration-ec2"

VPN_IDS=(
  "vpn-0cfda8ec06cb13f76"
  "vpn-05eddd53cfced8039"
  "vpn-0b9a79b9e66c7215d"
)

CGW_IDS=(
  "cgw-079538efdd065d3b1"
  "cgw-0eb1ae8fb9ceecdf2"
  "cgw-0a849f3f2e4918c5d"
)

S3_BUCKETS=(
  "arpit-aws-gcp-migration-source-2026"
  "arpit-aws-gcp-migration-logs-2026"
)

export AWS_PAGER=""

command -v aws >/dev/null || { echo "ERROR: AWS CLI is required."; exit 1; }
command -v jq  >/dev/null || { echo "ERROR: Install jq first: brew install jq"; exit 1; }

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

if [[ "$ACCOUNT" != "$EXPECTED_ACCOUNT" ]]; then
  echo "ERROR: Wrong AWS account: $ACCOUNT"
  exit 1
fi

echo "AWS account: $ACCOUNT"
echo "Region:      $REGION"
echo "VPC:         $VPC_ID"
echo
echo "WARNING: This permanently deletes the identified migration lab,"
echo "including the RDS database and both S3 buckets listed in this script."
echo "Confirm that the GCP transfer succeeded and destination data was verified."
echo
read -r -p 'Type DELETE-AWS-MIGRATION-LAB to continue: ' CONFIRM
[[ "$CONFIRM" == "DELETE-AWS-MIGRATION-LAB" ]] || {
  echo "Cancelled."
  exit 1
}

# 1. Delete the lab EC2 instance.
echo "== EC2 =="
if aws ec2 describe-instances --region "$REGION" \
  --instance-ids "$EC2_ID" >/dev/null 2>&1; then
  aws ec2 terminate-instances --region "$REGION" \
    --instance-ids "$EC2_ID" || true
  aws ec2 wait instance-terminated --region "$REGION" \
    --instance-ids "$EC2_ID" || true
fi

# 2. Delete the RDS database without a final snapshot.
echo "== RDS =="
if aws rds describe-db-instances --region "$REGION" \
  --db-instance-identifier "$RDS_ID" >/dev/null 2>&1; then
  aws rds modify-db-instance --region "$REGION" \
    --db-instance-identifier "$RDS_ID" \
    --no-deletion-protection --apply-immediately || true

  aws rds wait db-instance-available --region "$REGION" \
    --db-instance-identifier "$RDS_ID" || true

  aws rds delete-db-instance --region "$REGION" \
    --db-instance-identifier "$RDS_ID" \
    --skip-final-snapshot --delete-automated-backups || {
      echo "ERROR: RDS deletion failed. Stopping before network cleanup."
      exit 1
    }

  aws rds wait db-instance-deleted --region "$REGION" \
    --db-instance-identifier "$RDS_ID"
fi

# 3. Delete all identified VPN connections.
echo "== VPN connections =="
for id in "${VPN_IDS[@]}"; do
  aws ec2 delete-vpn-connection --region "$REGION" \
    --vpn-connection-id "$id" 2>/dev/null || true
done

# 4. Detach and delete the virtual private gateway.
echo "== Virtual Private Gateway =="
aws ec2 detach-vpn-gateway --region "$REGION" \
  --vpn-gateway-id "$VGW_ID" --vpc-id "$VPC_ID" 2>/dev/null || true

for attempt in {1..30}; do
  ATTACHMENT=$(aws ec2 describe-vpn-gateways --region "$REGION" \
    --vpn-gateway-ids "$VGW_ID" \
    --query 'VpnGateways[0].VpcAttachments[0].State' \
    --output text 2>/dev/null || true)
  [[ "$ATTACHMENT" == "detached" || "$ATTACHMENT" == "None" ]] && break
  sleep 10
done

aws ec2 delete-vpn-gateway --region "$REGION" \
  --vpn-gateway-id "$VGW_ID" 2>/dev/null || true

# 5. Delete customer gateways after their VPN connections.
echo "== Customer Gateways =="
sleep 15
for id in "${CGW_IDS[@]}"; do
  aws ec2 delete-customer-gateway --region "$REGION" \
    --customer-gateway-id "$id" 2>/dev/null || true
done

# 6. Delete the two S3 buckets, including object versions and delete markers.
# This is irreversible. Bucket names are explicitly allowlisted above.
echo "== S3 buckets =="
for bucket in "${S3_BUCKETS[@]}"; do
  if ! aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
    echo "Skipping missing or inaccessible bucket: $bucket"
    continue
  fi

  VERSIONING=$(aws s3api get-bucket-versioning --bucket "$bucket" \
    --query 'Status' --output text 2>/dev/null || true)

  if [[ "$VERSIONING" == "Enabled" || "$VERSIONING" == "Suspended" ]]; then
    while true; do
      PAGE=$(aws s3api list-object-versions --bucket "$bucket" --output json)
      DELETE_JSON=$(jq -c '{
        Objects: ([.Versions[]?, .DeleteMarkers[]?] |
          map({Key:.Key, VersionId:.VersionId})),
        Quiet: true
      }' <<< "$PAGE")
      COUNT=$(jq '.Objects | length' <<< "$DELETE_JSON")
      [[ "$COUNT" -eq 0 ]] && break
      aws s3api delete-objects --bucket "$bucket" \
        --delete "$DELETE_JSON" >/dev/null
    done
  else
    aws s3 rm "s3://$bucket" --recursive
  fi

  aws s3api delete-bucket --bucket "$bucket" \
    --region "$REGION"
done

# 7. Delete lab NAT gateways and VPC endpoints, if present.
echo "== VPC endpoints and NAT gateways =="
ENDPOINTS=$(aws ec2 describe-vpc-endpoints --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[].VpcEndpointId' --output text)

if [[ -n "$ENDPOINTS" && "$ENDPOINTS" != "None" ]]; then
  aws ec2 delete-vpc-endpoints --region "$REGION" \
    --vpc-endpoint-ids $ENDPOINTS || true
fi

NATS=$(aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query "NatGateways[?State!='deleted'].NatGatewayId" --output text)

for id in $NATS; do
  aws ec2 delete-nat-gateway --region "$REGION" \
    --nat-gateway-id "$id" || true
done

for attempt in {1..40}; do
  REMAINING=$(aws ec2 describe-nat-gateways --region "$REGION" \
    --filter "Name=vpc-id,Values=$VPC_ID" \
    --query "length(NatGateways[?State=='available' || State=='deleting'])" \
    --output text)
  [[ "$REMAINING" == "0" ]] && break
  sleep 10
done

# Release Elastic IPs associated with lab NAT gateways/instances only
# when they are no longer associated with a network interface.
ADDRESSES=$(aws ec2 describe-addresses --region "$REGION" --output json)
while IFS=$'\t' read -r ALLOC IP; do
  [[ -z "$ALLOC" || "$ALLOC" == "None" ]] && continue
  aws ec2 release-address --region "$REGION" \
    --allocation-id "$ALLOC" 2>/dev/null || true
done < <(jq -r --arg vpc "$VPC_ID" \
  '.Addresses[] | select(.NetworkInterfaceId == null) |
   [.AllocationId // "", .PublicIp] | @tsv' <<< "$ADDRESSES")

# 8. Remove remaining lab network interfaces, subnets, route tables,
# internet gateways, and non-default security groups.
echo "== VPC network cleanup =="

# Any remaining ENI can indicate a resource that still needs deletion.
ENIS=$(aws ec2 describe-network-interfaces --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkInterfaces[].NetworkInterfaceId' --output text)

if [[ -n "$ENIS" && "$ENIS" != "None" ]]; then
  echo "Remaining ENIs detected:"
  aws ec2 describe-network-interfaces --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'NetworkInterfaces[].{ID:NetworkInterfaceId,Status:Status,Description:Description}' \
    --output table
  echo "Delete the owning resource for any remaining ENI, then rerun this script."
  exit 1
fi

# Delete non-main route tables after disassociating explicit associations.
RTS=$(aws ec2 describe-route-tables --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[].RouteTableId' --output text)

for rt in $RTS; do
  MAIN=$(aws ec2 describe-route-tables --region "$REGION" \
    --route-table-ids "$rt" \
    --query 'RouteTables[0].Associations[?Main==`true`] | length(@)' \
    --output text)
  [[ "$MAIN" == "1" ]] && continue

  ASSOCS=$(aws ec2 describe-route-tables --region "$REGION" \
    --route-table-ids "$rt" \
    --query 'RouteTables[0].Associations[?Main!=`true`].RouteTableAssociationId' \
    --output text)

  for assoc in $ASSOCS; do
    aws ec2 disassociate-route-table --region "$REGION" \
      --association-id "$assoc" 2>/dev/null || true
  done
  aws ec2 delete-route-table --region "$REGION" \
    --route-table-id "$rt" 2>/dev/null || true
done

# Delete subnets.
SUBNETS=$(aws ec2 describe-subnets --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[].SubnetId' --output text)
for subnet in $SUBNETS; do
  aws ec2 delete-subnet --region "$REGION" \
    --subnet-id "$subnet" || true
done

# Detach/delete attached Internet Gateways.
IGWS=$(aws ec2 describe-internet-gateways --region "$REGION" \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[].InternetGatewayId' --output text)
for igw in $IGWS; do
  aws ec2 detach-internet-gateway --region "$REGION" \
    --internet-gateway-id "$igw" --vpc-id "$VPC_ID" 2>/dev/null || true
  aws ec2 delete-internet-gateway --region "$REGION" \
    --internet-gateway-id "$igw" 2>/dev/null || true
done

# Delete non-default security groups.
SGS=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
for sg in $SGS; do
  aws ec2 delete-security-group --region "$REGION" \
    --group-id "$sg" 2>/dev/null || true
done

# Delete custom RDS subnet groups associated with this VPC.
DBSGS=$(aws rds describe-db-subnet-groups --region "$REGION" \
  --query "DBSubnetGroups[?VpcId=='$VPC_ID'].DBSubnetGroupName" \
  --output text)
for name in $DBSGS; do
  [[ "$name" == "default" ]] && continue
  aws rds delete-db-subnet-group --region "$REGION" \
    --db-subnet-group-name "$name" 2>/dev/null || true
done

# Delete the VPC only if AWS allows it.
aws ec2 delete-vpc --region "$REGION" --vpc-id "$VPC_ID" || {
  echo "VPC still has dependencies. Inspect remaining resources before retrying."
}

# 9. Remove EC2 IAM role policies, instance profiles, then role.
echo "== IAM role cleanup =="

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  PROFILES=$(aws iam list-instance-profiles-for-role \
    --role-name "$ROLE_NAME" \
    --query 'InstanceProfiles[].InstanceProfileName' --output text)

  for profile in $PROFILES; do
    aws iam remove-role-from-instance-profile \
      --instance-profile-name "$profile" \
      --role-name "$ROLE_NAME" 2>/dev/null || true
    aws iam delete-instance-profile \
      --instance-profile-name "$profile" 2>/dev/null || true
  done

  ATTACHED=$(aws iam list-attached-role-policies \
    --role-name "$ROLE_NAME" \
    --query 'AttachedPolicies[].PolicyArn' --output text)
  for arn in $ATTACHED; do
    aws iam detach-role-policy --role-name "$ROLE_NAME" \
      --policy-arn "$arn"
  done

  INLINE=$(aws iam list-role-policies \
    --role-name "$ROLE_NAME" --query 'PolicyNames[]' --output text)
  for policy in $INLINE; do
    aws iam delete-role-policy --role-name "$ROLE_NAME" \
      --policy-name "$policy"
  done

  aws iam delete-role --role-name "$ROLE_NAME"
fi

echo
echo "Cleanup script finished. Review any errors above."
echo "Check AWS Billing and remaining resources manually."

