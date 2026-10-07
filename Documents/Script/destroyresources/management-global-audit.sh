#!/bin/bash

set +e

echo "=============================================================="
echo " MANAGEMENT ACCOUNT GLOBAL FINAL AUDIT"
echo "=============================================================="

echo
echo "=== IDENTITY ==="
aws sts get-caller-identity \
  --query '{Account:Account,Arn:Arn}' \
  --output table

echo
echo "=== ORGANIZATION ==="
aws organizations describe-organization \
  --query 'Organization.{Id:Id,MasterAccountId:MasterAccountId,FeatureSet:FeatureSet}' \
  --output table

echo
echo "=== ACCOUNTS ==="
aws organizations list-accounts \
  --query 'Accounts[].{Id:Id,Name:Name,State:State}' \
  --output table

echo
echo "=== CONTROL TOWER ==="
aws controltower get-landing-zone-operation \
  --region us-east-1 \
  --operation-identifier "39069289-0544-4325-9bd5-c7adf8e7f289" \
  --query 'operationDetails.{Type:operationType,Status:status,Start:startTime,Error:errorDetails}' \
  --output table

echo
echo "=== IDENTITY CENTER ==="
aws sso-admin list-instances \
  --region us-east-1 \
  --query 'Instances[].{ARN:InstanceArn,IdentityStore:IdentityStoreId,Owner:OwnerAccountId,Status:Status}' \
  --output table

echo
echo "=============================================================="
echo " GLOBAL IAM"
echo "=============================================================="

echo
echo "--- IAM USERS ---"
aws iam list-users \
  --query 'Users[].{Name:UserName,Created:CreateDate}' \
  --output table

echo
echo "--- IAM ROLES ---"
aws iam list-roles \
  --query 'Roles[].{Name:RoleName,Created:CreateDate}' \
  --output table

echo
echo "--- CUSTOMER MANAGED IAM POLICIES ---"
aws iam list-policies \
  --scope Local \
  --query 'Policies[].{Name:PolicyName,Arn:Arn}' \
  --output table

echo
echo "--- IAM GROUPS ---"
aws iam list-groups \
  --query 'Groups[].GroupName' \
  --output table

echo
echo "=============================================================="
echo " GLOBAL S3"
echo "=============================================================="

aws s3api list-buckets \
  --query 'Buckets[].{Name:Name,Created:CreationDate}' \
  --output table

echo
echo "=============================================================="
echo " ROUTE 53"
echo "=============================================================="

echo "--- HOSTED ZONES ---"
aws route53 list-hosted-zones \
  --query 'HostedZones[].{Name:Name,Id:Id,Private:Config.PrivateZone}' \
  --output table

echo
echo "--- HEALTH CHECKS ---"
aws route53 list-health-checks \
  --query 'HealthChecks[].Id' \
  --output table

echo
echo "=============================================================="
echo " CLOUDTRAIL"
echo "=============================================================="

aws cloudtrail describe-trails \
  --query 'trailList[].{Name:Name,S3Bucket:S3BucketName,HomeRegion:HomeRegion}' \
  --output table

echo
echo "=============================================================="
echo " CLOUDFORMATION - ALL ENABLED REGIONS"
echo "=============================================================="

REGIONS=$(aws account list-regions \
  --query 'Regions[?RegionOptStatus==`ENABLED` || RegionOptStatus==`ENABLED_BY_DEFAULT`].RegionName' \
  --output text)

for REGION in $REGIONS; do
    echo
    echo "--- $REGION ---"

    aws cloudformation list-stacks \
      --region "$REGION" \
      --stack-status-filter \
        CREATE_IN_PROGRESS \
        CREATE_COMPLETE \
        UPDATE_IN_PROGRESS \
        UPDATE_COMPLETE \
        UPDATE_COMPLETE_CLEANUP_IN_PROGRESS \
        DELETE_FAILED \
      --query 'StackSummaries[].{Name:StackName,Status:StackStatus}' \
      --output table 2>/dev/null
done

echo
echo "=============================================================="
echo " EBS SNAPSHOTS - ALL REGIONS"
echo "=============================================================="

for REGION in $REGIONS; do
    echo
    echo "--- $REGION ---"

    aws ec2 describe-snapshots \
      --region "$REGION" \
      --owner-ids self \
      --query 'Snapshots[].{ID:SnapshotId,Size:VolumeSize,State:State,Description:Description}' \
      --output table 2>/dev/null
done

echo
echo "=============================================================="
echo " RESOURCE EXPLORER"
echo "=============================================================="

for REGION in $REGIONS; do
    echo
    echo "--- $REGION ---"

    aws resource-explorer-2 list-indexes \
      --region "$REGION" \
      --query 'Indexes[].{ARN:Arn,Type:Type,Status:Status}' \
      --output table 2>/dev/null
done

echo
echo "=============================================================="
echo " GLOBAL AUDIT COMPLETE"
echo "=============================================================="
