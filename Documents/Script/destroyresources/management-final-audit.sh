#!/bin/bash

set +e

echo "=============================================================="
echo " AWS MANAGEMENT ACCOUNT - FINAL RESOURCE AUDIT"
echo "=============================================================="

ACCOUNT=$(aws sts get-caller-identity \
  --query 'Account' \
  --output text 2>/dev/null)

ARN=$(aws sts get-caller-identity \
  --query 'Arn' \
  --output text 2>/dev/null)

echo
echo "Account : $ACCOUNT"
echo "Identity: $ARN"

if [ "$ACCOUNT" != "211811255273" ]; then
    echo
    echo "ERROR: You are NOT connected to management account 211811255273"
    echo "Stopping."
    exit 1
fi

echo
echo "=============================================================="
echo "1. AWS ORGANIZATION"
echo "=============================================================="

aws organizations describe-organization \
  --query 'Organization.{Id:Id,MasterAccountId:MasterAccountId,FeatureSet:FeatureSet}' \
  --output table

echo
echo "=== ORGANIZATION ACCOUNTS ==="

aws organizations list-accounts \
  --query 'Accounts[].{Id:Id,Name:Name,State:State,JoinedMethod:JoinedMethod}' \
  --output table

echo
echo "=============================================================="
echo "2. CONTROL TOWER"
echo "=============================================================="

aws controltower list-landing-zones \
  --region us-east-1 \
  --query 'landingZones[].arn' \
  --output table

echo
echo "=== CONTROL TOWER OPERATIONS ==="

echo "If you know the operation ID:"
echo "39069289-0544-4325-9bd5-c7adf8e7f289"

aws controltower get-landing-zone-operation \
  --region us-east-1 \
  --operation-identifier "39069289-0544-4325-9bd5-c7adf8e7f289" \
  --output table 2>/dev/null

echo
echo "=============================================================="
echo "3. IAM IDENTITY CENTER"
echo "=============================================================="

aws sso-admin list-instances \
  --region us-east-1 \
  --query 'Instances[].{InstanceArn:InstanceArn,IdentityStore:IdentityStoreId,Owner:OwnerAccountId,Status:Status}' \
  --output table

echo
echo "=============================================================="
echo "4. ENABLED AWS REGIONS"
echo "=============================================================="

REGIONS=$(aws account list-regions \
  --region us-east-1 \
  --query 'Regions[?RegionOptStatus==`ENABLED` || RegionOptStatus==`ENABLED_BY_DEFAULT`].RegionName' \
  --output text)

echo "$REGIONS"

echo
echo "=============================================================="
echo "5. REGIONAL RESOURCE SCAN"
echo "=============================================================="

for REGION in $REGIONS
do

    echo
    echo "##############################################################"
    echo " REGION: $REGION"
    echo "##############################################################"

    echo
    echo "--- EC2 INSTANCES ---"

    aws ec2 describe-instances \
      --region "$REGION" \
      --query 'Reservations[].Instances[?State.Name!=`terminated`].{ID:InstanceId,State:State.Name,Type:InstanceType}' \
      --output table 2>/dev/null

    echo
    echo "--- VPCS ---"

    aws ec2 describe-vpcs \
      --region "$REGION" \
      --query 'Vpcs[].{VPC:VpcId,CIDR:CidrBlock,Default:IsDefault}' \
      --output table 2>/dev/null

    echo
    echo "--- SUBNETS ---"

    aws ec2 describe-subnets \
      --region "$REGION" \
      --query 'Subnets[].{Subnet:SubnetId,VPC:VpcId,CIDR:CidrBlock,AZ:AvailabilityZone}' \
      --output table 2>/dev/null

    echo
    echo "--- NAT GATEWAYS ---"

    aws ec2 describe-nat-gateways \
      --region "$REGION" \
      --filter Name=state,Values=pending,available,deleting \
      --query 'NatGateways[].{NAT:NatGatewayId,State:State,VPC:VpcId}' \
      --output table 2>/dev/null

    echo
    echo "--- ELASTIC IPs ---"

    aws ec2 describe-addresses \
      --region "$REGION" \
      --query 'Addresses[].{IP:PublicIp,Allocation:AllocationId,Association:AssociationId}' \
      --output table 2>/dev/null

    echo
    echo "--- LOAD BALANCERS ---"

    aws elbv2 describe-load-balancers \
      --region "$REGION" \
      --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,State:State.Code}' \
      --output table 2>/dev/null

    echo
    echo "--- EKS ---"

    aws eks list-clusters \
      --region "$REGION" \
      --output table 2>/dev/null

    echo
    echo "--- RDS ---"

    aws rds describe-db-instances \
      --region "$REGION" \
      --query 'DBInstances[].{DB:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine}' \
      --output table 2>/dev/null

    echo
    echo "--- AURORA/RDS CLUSTERS ---"

    aws rds describe-db-clusters \
      --region "$REGION" \
      --query 'DBClusters[].{Cluster:DBClusterIdentifier,Status:Status,Engine:Engine}' \
      --output table 2>/dev/null

    echo
    echo "--- ELASTICACHE ---"

    aws elasticache describe-cache-clusters \
      --region "$REGION" \
      --query 'CacheClusters[].{ID:CacheClusterId,Status:CacheClusterStatus,Engine:Engine}' \
      --output table 2>/dev/null

    echo
    echo "--- OPENSEARCH ---"

    aws opensearch list-domain-names \
      --region "$REGION" \
      --query 'DomainNames[].DomainName' \
      --output table 2>/dev/null

    echo
    echo "--- LAMBDA ---"

    aws lambda list-functions \
      --region "$REGION" \
      --query 'Functions[].FunctionName' \
      --output table 2>/dev/null

    echo
    echo "--- DYNAMODB ---"

    aws dynamodb list-tables \
      --region "$REGION" \
      --output table 2>/dev/null

    echo
    echo "--- ECR ---"

    aws ecr describe-repositories \
      --region "$REGION" \
      --query 'repositories[].{Repository:repositoryName,URI:repositoryUri}' \
      --output table 2>/dev/null

    echo
    echo "--- S3 CONTROL-PLANE REGIONAL CHECK ---"

    aws s3api list-buckets \
      --query 'Buckets[].Name' \
      --output table 2>/dev/null

    echo
    echo "--- CLOUDWATCH LOG GROUPS ---"

    aws logs describe-log-groups \
      --region "$REGION" \
      --query 'logGroups[].{Name:logGroupName,StoredBytes:storedBytes}' \
      --output table 2>/dev/null

    echo
    echo "--- KMS KEYS ---"

    aws kms list-keys \
      --region "$REGION" \
      --query 'Keys[].KeyId' \
      --output table 2>/dev/null

    echo
    echo "--- SECRETS MANAGER ---"

    aws secretsmanager list-secrets \
      --region "$REGION" \
      --query 'SecretList[].{Name:Name,ARN:ARN}' \
      --output table 2>/dev/null

    echo
    echo "--- SQS ---"

    aws sqs list-queues \
      --region "$REGION" \
      --output table 2>/dev/null

    echo
    echo "--- SNS ---"

    aws sns list-topics \
      --region "$REGION" \
      --query 'Topics[].TopicArn' \
      --output table 2>/dev/null

    echo
    echo "--- API GATEWAY ---"

    aws apigateway get-rest-apis \
      --region "$REGION" \
      --query 'items[].{ID:id,Name:name}' \
      --output table 2>/dev/null

    echo
    echo "--- CLOUDTRAIL ---"

    aws cloudtrail describe-trails \
      --region "$REGION" \
      --query 'trailList[].{Name:Name,S3:S3BucketName}' \
      --output table 2>/dev/null

    echo
    echo "--- CONFIG ---"

    aws configservice describe-configuration-recorders \
      --region "$REGION" \
      --query 'ConfigurationRecorders[].name' \
      --output table 2>/dev/null

    echo
    echo "--- GUARD DUTY ---"

    aws guardduty list-detectors \
      --region "$REGION" \
      --output table 2>/dev/null

    echo
    echo "--- SECURITY HUB ---"

    aws securityhub describe-hub \
      --region "$REGION" \
      --output table 2>/dev/null

done

echo
echo "=============================================================="
echo "6. GLOBAL / ACCOUNT LEVEL RESOURCES"
echo "=============================================================="

echo
echo "--- IAM USERS ---"

aws iam list-users \
  --query 'Users[].{User:UserName,Created:CreateDate}' \
  --output table

echo
echo "--- IAM ROLES ---"

aws iam list-roles \
  --query 'Roles[].RoleName' \
  --output table

echo
echo "--- IAM POLICIES ---"

aws iam list-policies \
  --scope Local \
  --query 'Policies[].{Name:PolicyName,ARN:Arn}' \
  --output table

echo
echo "--- IAM GROUPS ---"

aws iam list-groups \
  --query 'Groups[].GroupName' \
  --output table

echo
echo "--- S3 BUCKETS ---"

aws s3api list-buckets \
  --query 'Buckets[].{Name:Name,Created:CreationDate}' \
  --output table

echo
echo "--- ROUTE53 HOSTED ZONES ---"

aws route53 list-hosted-zones \
  --query 'HostedZones[].{Name:Name,Id:Id}' \
  --output table

echo
echo "--- ROUTE53 HEALTH CHECKS ---"

aws route53 list-health-checks \
  --query 'HealthChecks[].Id' \
  --output table

echo
echo "--- CLOUDFORMATION STACKS ---"

for REGION in $REGIONS
do
    echo
    echo "CloudFormation - $REGION"

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
echo "7. EC2 SNAPSHOTS"
echo "=============================================================="

aws ec2 describe-snapshots \
  --owner-ids self \
  --query 'Snapshots[].{Snapshot:SnapshotId,Volume:VolumeId,Size:VolumeSize,State:State}' \
  --output table

echo
echo "=============================================================="
echo "8. EBS VOLUMES - ALL REGIONS"
echo "=============================================================="

for REGION in $REGIONS
do
    aws ec2 describe-volumes \
      --region "$REGION" \
      --query 'Volumes[].{Volume:VolumeId,State:State,Size:Size,Type:VolumeType}' \
      --output table 2>/dev/null
done

echo
echo "=============================================================="
echo "9. RESOURCE EXPLORER"
echo "=============================================================="

echo "Checking Resource Explorer indexes..."

for REGION in $REGIONS
do
    echo
    echo "Resource Explorer - $REGION"

    aws resource-explorer-2 list-indexes \
      --region "$REGION" \
      --query 'Indexes[].{ARN:Arn,Type:Type,Status:Status}' \
      --output table 2>/dev/null
done

echo
echo "=============================================================="
echo " AUDIT COMPLETE"
echo "=============================================================="
echo "NO RESOURCES WERE DELETED."
echo "=============================================================="
