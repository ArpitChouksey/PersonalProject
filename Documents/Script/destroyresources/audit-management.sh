#!/bin/bash

set -u

PROFILE="management"
REGION="us-east-1"

echo "============================================================"
echo " AWS MANAGEMENT ACCOUNT FINAL AUDIT"
echo "============================================================"

echo
echo ">>> ACCOUNT"
aws sts get-caller-identity \
  --profile "$PROFILE" \
  --region "$REGION"

echo
echo "============================================================"
echo " CONTROL TOWER"
echo "============================================================"

aws controltower get-landing-zone \
  --profile "$PROFILE" \
  --region "$REGION" \
  --output table 2>/dev/null || echo "Control Tower landing zone not found / API unavailable."

echo
echo "============================================================"
echo " ORGANIZATION"
echo "============================================================"

aws organizations describe-organization \
  --profile "$PROFILE" \
  --output table

echo
echo ">>> ORGANIZATION ACCOUNTS"

aws organizations list-accounts \
  --profile "$PROFILE" \
  --query 'Accounts[].{Name:Name,Id:Id,Email:Email,Status:Status}' \
  --output table

echo
echo "============================================================"
echo " IAM IDENTITY CENTER"
echo "============================================================"

aws sso-admin list-instances \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Instances[].{InstanceArn:InstanceArn,IdentityStore:IdentityStoreId,Status:Status}' \
  --output table

echo
echo "============================================================"
echo " IAM ROLES"
echo "============================================================"

aws iam list-roles \
  --profile "$PROFILE" \
  --query 'Roles[].RoleName' \
  --output table

echo
echo "============================================================"
echo " S3 BUCKETS"
echo "============================================================"

aws s3api list-buckets \
  --profile "$PROFILE" \
  --query 'Buckets[].Name' \
  --output table

echo
echo "============================================================"
echo " EC2 / VPC"
echo "============================================================"

aws ec2 describe-vpcs \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,Default:IsDefault}' \
  --output table

echo
echo ">>> EC2 INSTANCES"

aws ec2 describe-instances \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}' \
  --output table

echo
echo "============================================================"
echo " EKS"
echo "============================================================"

aws eks list-clusters \
  --profile "$PROFILE" \
  --region "$REGION" \
  --output table

echo
echo "============================================================"
echo " RDS"
echo "============================================================"

aws rds describe-db-instances \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'DBInstances[].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus}' \
  --output table

echo
echo "============================================================"
echo " NAT GATEWAYS"
echo "============================================================"

aws ec2 describe-nat-gateways \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'NatGateways[].{Id:NatGatewayId,State:State}' \
  --output table

echo
echo "============================================================"
echo " ELASTIC IPS"
echo "============================================================"

aws ec2 describe-addresses \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Addresses[].{AllocationId:AllocationId,PublicIp:PublicIp,Instance:InstanceId}' \
  --output table

echo
echo "============================================================"
echo " CLOUDWATCH LOG GROUPS"
echo "============================================================"

aws logs describe-log-groups \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'logGroups[].{Name:logGroupName,StoredBytes:storedBytes}' \
  --output table

echo
echo "============================================================"
echo " KMS KEYS"
echo "============================================================"

aws kms list-keys \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Keys[].KeyId' \
  --output table

echo
echo "============================================================"
echo " SECRETS MANAGER"
echo "============================================================"

aws secretsmanager list-secrets \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'SecretList[].Name' \
  --output table

echo
echo "============================================================"
echo " LAMBDA"
echo "============================================================"

aws lambda list-functions \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'Functions[].FunctionName' \
  --output table

echo
echo "============================================================"
echo " DYNAMODB"
echo "============================================================"

aws dynamodb list-tables \
  --profile "$PROFILE" \
  --region "$REGION" \
  --output table

echo
echo "============================================================"
echo " CLOUDTRAIL"
echo "============================================================"

aws cloudtrail describe-trails \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'trailList[].{Name:Name,S3Bucket:S3BucketName,HomeRegion:HomeRegion}' \
  --output table

echo
echo "============================================================"
echo " CONFIG"
echo "============================================================"

aws configservice describe-configuration-recorders \
  --profile "$PROFILE" \
  --region "$REGION" \
  --output table 2>/dev/null || true

echo
echo "============================================================"
echo " GUARD DUTY"
echo "============================================================"

aws guardduty list-detectors \
  --profile "$PROFILE" \
  --region "$REGION" \
  --output table 2>/dev/null || true

echo
echo "============================================================"
echo " SECURITY HUB"
echo "============================================================"

aws securityhub describe-hub \
  --profile "$PROFILE" \
  --region "$REGION" \
  --output table 2>/dev/null || true

echo
echo "============================================================"
echo " MANAGEMENT ACCOUNT AUDIT COMPLETE"
echo "============================================================"
