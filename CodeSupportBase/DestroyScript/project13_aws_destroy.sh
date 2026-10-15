#!/usr/bin/env bash
set -Eeuo pipefail

EXPECTED_ACCOUNT="211811255273"
REGION="us-east-1"
STACK="project13-storage-mover-connector"
BUCKET="migration-source-v1"

die() { echo "ERROR: $*" >&2; exit 1; }

command -v aws >/dev/null || die "Install AWS CLI first."
command -v jq >/dev/null || die "Install jq: brew install jq"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ARN=$(aws sts get-caller-identity --query Arn --output text)

[[ "$ACCOUNT" == "$EXPECTED_ACCOUNT" ]] ||
  die "Wrong AWS account. Expected $EXPECTED_ACCOUNT, got $ACCOUNT ($ARN)."

echo "AWS Account: $ACCOUNT"
echo "Identity: $ARN"
echo "Region: $REGION"
echo "CloudFormation stack: $STACK"
echo "S3 bucket: $BUCKET"
echo
echo "WARNING: The S3 bucket and all versions will be permanently deleted."
echo

echo "===== STACK STATUS ====="
if aws cloudformation describe-stacks --region "$REGION" \
  --stack-name "$STACK" >/dev/null 2>&1; then

  aws cloudformation describe-stacks --region "$REGION" \
    --stack-name "$STACK" \
    --query 'Stacks[0].[StackName,StackStatus,StackId]' --output table

  aws cloudformation list-stack-resources --region "$REGION" \
    --stack-name "$STACK" \
    --query 'StackResourceSummaries[].{Resource:LogicalResourceId,Type:ResourceType,PhysicalId:PhysicalResourceId,Status:ResourceStatus}' \
    --output table || true
else
  echo "Stack not found."
fi

echo
echo "===== S3 BUCKET CHECK ====="
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  aws s3api get-bucket-location --bucket "$BUCKET" \
    --query LocationConstraint --output text
  aws s3api list-object-versions --bucket "$BUCKET" \
    --query '{Versions:length(Versions[]),DeleteMarkers:length(DeleteMarkers[])}' \
    --output json || true
else
  echo "Bucket absent or not accessible."
fi

echo
echo "===== REGIONAL LEFTOVER INVENTORY (READ ONLY) ====="
REGIONS=$(aws ec2 describe-regions --all-regions \
  --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].RegionName" \
  --output text)

for r in $REGIONS; do
  echo "--- $r ---"

  aws cloudformation list-stacks --region "$r" \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE ROLLBACK_COMPLETE IMPORT_COMPLETE \
    --query "StackSummaries[?contains(to_lower(StackName), 'project13') || contains(to_lower(StackName), 'migration') || contains(to_lower(StackName), 'storage-mover')].[StackName,StackStatus]" \
    --output table 2>/dev/null || true

  aws ec2 describe-volumes --region "$r" \
    --query "Volumes[?Tags && (contains(to_string(Tags), 'project13') || contains(to_string(Tags), 'migration'))].[VolumeId,State,Tags]" \
    --output table 2>/dev/null || true

  aws ec2 describe-addresses --region "$r" \
    --query "Addresses[?Tags && (contains(to_string(Tags), 'project13') || contains(to_string(Tags), 'migration'))].[AllocationId,PublicIp,Tags]" \
    --output table 2>/dev/null || true
done

echo
echo "Review the inventory above before proceeding."
read -r -p "Type DELETE-PROJECT13-AWS to delete the stack and bucket: " CONFIRM
[[ "$CONFIRM" == "DELETE-PROJECT13-AWS" ]] ||
  die "Confirmation did not match. No deletion performed."

echo
echo "===== DELETING CLOUDFORMATION STACK ====="
if aws cloudformation describe-stacks --region "$REGION" \
  --stack-name "$STACK" >/dev/null 2>&1; then
  aws cloudformation delete-stack --region "$REGION" --stack-name "$STACK"
  aws cloudformation wait stack-delete-complete \
    --region "$REGION" --stack-name "$STACK"
  echo "Stack deletion completed."
else
  echo "Stack already absent."
fi

echo
echo "===== DELETING S3 BUCKET AND ALL VERSIONS ====="
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  BUCKET_REGION=$(aws s3api get-bucket-location --bucket "$BUCKET" \
    --query LocationConstraint --output text)
  [[ "$BUCKET_REGION" == "None" || -z "$BUCKET_REGION" ]] &&
    BUCKET_REGION="us-east-1"

  while true; do
    PAGE=$(aws s3api list-object-versions --bucket "$BUCKET" \
      --region "$BUCKET_REGION" --max-items 1000 --output json)

    ITEMS=$(printf '%s' "$PAGE" | jq \
      '[((.Versions // [])[] | {Key:.Key,VersionId:.VersionId}), ((.DeleteMarkers // [])[] | {Key:.Key,VersionId:.VersionId})]')

    COUNT=$(printf '%s' "$ITEMS" | jq 'length')
    [[ "$COUNT" -gt 0 ]] || break

    printf '%s' "$ITEMS" | jq -c '{Objects: ., Quiet: true}' \
      > /tmp/project13-s3-delete-batch.json

    aws s3api delete-objects --bucket "$BUCKET" \
      --region "$BUCKET_REGION" \
      --delete file:///tmp/project13-s3-delete-batch.json
  done

  aws s3 rm "s3://$BUCKET" --recursive --region "$BUCKET_REGION" || true
  aws s3api delete-bucket --bucket "$BUCKET" --region "$BUCKET_REGION"
  echo "Bucket deletion requested/completed."
else
  echo "Bucket already absent or not accessible."
fi

echo
echo "===== FINAL VERIFICATION ====="
if aws cloudformation describe-stacks --region "$REGION" \
  --stack-name "$STACK" >/dev/null 2>&1; then
  echo "WARNING: Stack still exists. Check CloudFormation events."
else
  echo "CloudFormation stack absent."
fi

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "WARNING: Bucket still exists or is accessible."
else
  echo "Bucket absent or inaccessible."
fi

echo
echo "IMPORTANT: This does not guarantee every project resource is gone."
echo "Check all regions for untagged resources, snapshots, EBS volumes,"
echo "Elastic IPs, CloudWatch logs, IAM roles, secrets, KMS keys and other buckets."
echo "Check AWS Billing -> Bills and Cost Explorer after cleanup."
