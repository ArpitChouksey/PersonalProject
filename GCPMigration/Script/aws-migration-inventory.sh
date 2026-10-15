#!/usr/bin/env bash

# AWS -> GCP Migration Lab
# READ-ONLY inventory. No resources are modified or deleted.

set -u

REGION="us-east-1"
OUT="aws-migration-inventory-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$OUT"
echo "Collecting AWS inventory in region: $REGION"
echo "Output directory: $OUT"

capture() {
  local file="$1"
  shift

  echo "Collecting: $file"
  if "$@" --output json > "$OUT/$file.json" 2> "$OUT/$file.error"; then
    rm -f "$OUT/$file.error"
  else
    echo "  Could not collect $file; check its .error file."
  fi
}

# Account and region
capture account aws sts get-caller-identity
capture region aws ec2 describe-availability-zones --region "$REGION"

# Networking
capture vpcs aws ec2 describe-vpcs --region "$REGION"
capture subnets aws ec2 describe-subnets --region "$REGION"
capture route-tables aws ec2 describe-route-tables --region "$REGION"
capture internet-gateways aws ec2 describe-internet-gateways --region "$REGION"
capture nat-gateways aws ec2 describe-nat-gateways --region "$REGION"
capture security-groups aws ec2 describe-security-groups --region "$REGION"
capture network-acls aws ec2 describe-network-acls --region "$REGION"
capture vpc-endpoints aws ec2 describe-vpc-endpoints --region "$REGION"

# Compute and storage
capture ec2-instances aws ec2 describe-instances --region "$REGION"
capture ebs-volumes aws ec2 describe-volumes --region "$REGION"
capture ebs-snapshots aws ec2 describe-snapshots \
  --owner-ids self --region "$REGION"

# RDS
capture rds-instances aws rds describe-db-instances --region "$REGION"
capture rds-subnet-groups aws rds describe-db-subnet-groups --region "$REGION"
capture rds-parameter-groups aws rds describe-db-parameter-groups --region "$REGION"

# IAM: migration role and instance profiles
capture migration-role aws iam get-role \
  --role-name role-aws-migration-ec2
capture migration-role-policies aws iam list-attached-role-policies \
  --role-name role-aws-migration-ec2
capture migration-role-inline-policies aws iam list-role-policies \
  --role-name role-aws-migration-ec2
capture migration-instance-profiles aws iam list-instance-profiles-for-role \
  --role-name role-aws-migration-ec2

# S3: bucket inventory (metadata only; no objects or object contents)
capture s3-buckets aws s3api list-buckets

if [ -s "$OUT/s3-buckets.json" ]; then
  while IFS= read -r bucket; do
    [ -z "$bucket" ] && continue

    safe_name=$(printf '%s' "$bucket" | tr '/:' '__')
    echo "Collecting S3 configuration: $bucket"

    capture "s3-${safe_name}-location" \
      aws s3api get-bucket-location --bucket "$bucket"

    capture "s3-${safe_name}-encryption" \
      aws s3api get-bucket-encryption --bucket "$bucket"

    capture "s3-${safe_name}-public-access-block" \
      aws s3api get-public-access-block --bucket "$bucket"

    capture "s3-${safe_name}-versioning" \
      aws s3api get-bucket-versioning --bucket "$bucket"

    capture "s3-${safe_name}-policy-status" \
      aws s3api get-bucket-policy-status --bucket "$bucket"

  done < <(jq -r \
    '.Buckets[]?.Name | select(test("migration"; "i"))' \
    "$OUT/s3-buckets.json")
fi

# KMS: metadata and aliases only
capture kms-aliases aws kms list-aliases --region "$REGION"
capture kms-keys aws kms list-keys --region "$REGION"

# Secrets Manager: names and metadata only, never secret values
capture secrets-metadata aws secretsmanager list-secrets \
  --region "$REGION" \
  --filters Key=name,Values=aws-gcp-migration

# CloudWatch
capture cloudwatch-log-groups aws logs describe-log-groups \
  --region "$REGION"

# Systems Manager: managed-instance status
capture ssm-managed-instances aws ssm describe-instance-information \
  --region "$REGION"

# Migration-related CloudTrail trails
capture cloudtrail-trails aws cloudtrail describe-trails \
  --region "$REGION"

echo
echo "Inventory collection finished."
echo "Files are saved in: $OUT"
echo "Review any .error files for missing permissions or absent resources."
echo "No AWS resources were changed."
