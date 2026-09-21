#!/bin/bash

set -u

REGION="us-east-1"
ACCOUNT_ID="211811255273"

VPC_ID="vpc-03afaff7b0e91ddeb"
EKS_CLUSTER="private-eks-platform"

S3_BUCKET="private-eks-platform-raw-logs-211811255273"
ECR_REPO="private-eks-platform"

REDIS_NAMESPACE="private-eks-analytics"
REDIS_WORKGROUP="private-eks-analytics"

SECRET_NAME="private-eks-platform/app/test"

echo "======================================================"
echo " AWS PROJECT CLEANUP VERIFICATION"
echo " Region : $REGION"
echo " Account: $ACCOUNT_ID"
echo "======================================================"

check() {
    echo
    echo "------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------"
}

# ------------------------------------------------------
# VPC
# ------------------------------------------------------

check "VPC"

aws ec2 describe-vpcs \
    --vpc-ids "$VPC_ID" \
    --region "$REGION" \
    --query 'Vpcs[].{VpcId:VpcId,State:State,Cidr:CidrBlock}' \
    --output table 2>/dev/null || echo "VPC NOT FOUND - CLEAN"


# ------------------------------------------------------
# SUBNETS
# ------------------------------------------------------

check "SUBNETS"

aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,State:State}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# ROUTE TABLES
# ------------------------------------------------------

check "ROUTE TABLES"

aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'RouteTables[].{RouteTableId:RouteTableId,VpcId:VpcId}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# INTERNET GATEWAYS
# ------------------------------------------------------

check "INTERNET GATEWAYS"

aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'InternetGateways[].InternetGatewayId' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# NAT GATEWAYS
# ------------------------------------------------------

check "NAT GATEWAYS"

aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'NatGateways[].{Id:NatGatewayId,State:State}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# VPC ENDPOINTS
# ------------------------------------------------------

check "VPC ENDPOINTS"

aws ec2 describe-vpc-endpoints \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'VpcEndpoints[].{Id:VpcEndpointId,Service:ServiceName,State:State}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# SECURITY GROUPS
# ------------------------------------------------------

check "SECURITY GROUPS"

aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'SecurityGroups[].{GroupId:GroupId,Name:GroupName}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# NETWORK INTERFACES
# ------------------------------------------------------

check "NETWORK INTERFACES"

aws ec2 describe-network-interfaces \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'NetworkInterfaces[].{Id:NetworkInterfaceId,Status:Status,Description:Description,PrivateIP:PrivateIpAddress}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# EC2 INSTANCES
# ------------------------------------------------------

check "EC2 INSTANCES"

aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name,PrivateIP:PrivateIpAddress}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# EBS VOLUMES
# ------------------------------------------------------

check "EBS VOLUMES"

aws ec2 describe-volumes \
    --filters "Name=tag:KubernetesCluster,Values=$EKS_CLUSTER" \
    --region "$REGION" \
    --query 'Volumes[].{VolumeId:VolumeId,State:State,Size:Size}' \
    --output table 2>/dev/null || true

echo
echo "Checking unattached EBS volumes in the region..."

aws ec2 describe-volumes \
    --filters "Name=status,Values=available" \
    --region "$REGION" \
    --query 'Volumes[].{VolumeId:VolumeId,Size:Size,CreateTime:CreateTime}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# EKS
# ------------------------------------------------------

check "EKS CLUSTER"

aws eks describe-cluster \
    --name "$EKS_CLUSTER" \
    --region "$REGION" \
    --query 'cluster.{Name:name,Status:status,Endpoint:endpoint}' \
    --output table 2>/dev/null || echo "EKS CLUSTER NOT FOUND - CLEAN"


check "EKS NODE GROUPS"

NODEGROUPS=$(aws eks list-nodegroups \
    --cluster-name "$EKS_CLUSTER" \
    --region "$REGION" \
    --query 'nodegroups[]' \
    --output text 2>/dev/null || true)

if [ -z "$NODEGROUPS" ]; then
    echo "NO NODE GROUPS - CLEAN"
else
    echo "$NODEGROUPS"
fi


check "EKS ADD-ONS"

aws eks list-addons \
    --cluster-name "$EKS_CLUSTER" \
    --region "$REGION" \
    --output table 2>/dev/null || echo "NO EKS ADD-ONS / CLUSTER NOT FOUND"


# ------------------------------------------------------
# ECR
# ------------------------------------------------------

check "ECR REPOSITORY"

aws ecr describe-repositories \
    --repository-names "$ECR_REPO" \
    --region "$REGION" \
    --query 'repositories[].{Repository:repositoryName,URI:repositoryUri}' \
    --output table 2>/dev/null || echo "ECR REPOSITORY NOT FOUND - CLEAN"


# ------------------------------------------------------
# S3
# ------------------------------------------------------

check "S3 BUCKET"

if aws s3api head-bucket \
    --bucket "$S3_BUCKET" \
    --region "$REGION" 2>/dev/null; then

    echo "WARNING: S3 BUCKET STILL EXISTS"

    aws s3api head-bucket \
        --bucket "$S3_BUCKET" \
        --region "$REGION"

else
    echo "S3 BUCKET NOT FOUND - CLEAN"
fi


# ------------------------------------------------------
# GLUE JOBS
# ------------------------------------------------------

check "GLUE JOBS"

aws glue get-jobs \
    --region "$REGION" \
    --query 'Jobs[].Name' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# GLUE CRAWLERS
# ------------------------------------------------------

check "GLUE CRAWLERS"

aws glue get-crawlers \
    --region "$REGION" \
    --query 'Crawlers[].Name' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# GLUE DATABASES
# ------------------------------------------------------

check "GLUE DATABASES"

aws glue get-databases \
    --region "$REGION" \
    --query 'DatabaseList[].Name' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# REDSHIFT SERVERLESS
# ------------------------------------------------------

check "REDSHIFT SERVERLESS NAMESPACE"

aws redshift-serverless get-namespace \
    --namespace-name "$REDIS_NAMESPACE" \
    --region "$REGION" \
    --query 'namespace.{Name:namespaceName,Status:status,DBName:dbName}' \
    --output table 2>/dev/null || echo "REDSHIFT NAMESPACE NOT FOUND - CLEAN"


check "REDSHIFT SERVERLESS WORKGROUP"

aws redshift-serverless get-workgroup \
    --workgroup-name "$REDIS_WORKGROUP" \
    --region "$REGION" \
    --query 'workgroup.{Name:workgroupName,Status:status,Endpoint:endpoint.address}' \
    --output table 2>/dev/null || echo "REDSHIFT WORKGROUP NOT FOUND - CLEAN"


# ------------------------------------------------------
# SECRETS MANAGER
# ------------------------------------------------------

check "SECRETS MANAGER"

aws secretsmanager describe-secret \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query '{Name:Name,ARN:ARN}' \
    --output table 2>/dev/null || echo "SECRET NOT FOUND - CLEAN"


# ------------------------------------------------------
# KMS
# ------------------------------------------------------

check "KMS ALIASES"

aws kms list-aliases \
    --region "$REGION" \
    --query 'Aliases[].{Alias:AliasName,TargetKeyId:TargetKeyId}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# CLOUDWATCH LOG GROUPS
# ------------------------------------------------------

check "CLOUDWATCH LOG GROUPS"

aws logs describe-log-groups \
    --region "$REGION" \
    --query 'logGroups[].logGroupName' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# LOAD BALANCERS
# ------------------------------------------------------

check "APPLICATION / NETWORK LOAD BALANCERS"

aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,VPC:VpcId,State:State.Code}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# IAM POLICIES
# ROLES INTENTIONALLY NOT CHECKED
# ------------------------------------------------------

check "CUSTOM IAM POLICIES"

aws iam list-policies \
    --scope Local \
    --query 'Policies[].{Name:PolicyName,ARN:Arn}' \
    --output table 2>/dev/null || true


# ------------------------------------------------------
# FINAL
# ------------------------------------------------------

echo
echo "======================================================"
echo " VERIFICATION COMPLETE"
echo "======================================================"

echo
echo "IAM ROLES WERE INTENTIONALLY NOT CHECKED."
echo
echo "Important:"
echo "This script is READ-ONLY."
echo "It does NOT delete anything."
echo
echo "Any remaining resource shown above should be reviewed"
echo "before considering the project completely cleaned up."
echo "======================================================"
