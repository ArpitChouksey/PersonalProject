#!/bin/bash

set -u

REGION="us-east-1"
OUT="aws-inventory-${REGION}-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$OUT"

echo "=============================================="
echo " AWS US-EAST-1 FULL INVENTORY"
echo " Region : $REGION"
echo " Output : $OUT"
echo "=============================================="

run() {
    NAME="$1"
    shift

    echo ""
    echo ">>> $NAME"

    "$@" > "$OUT/${NAME}.txt" 2>&1 || true
}

# ------------------------------------------------
# ACCOUNT / REGION
# ------------------------------------------------

run "caller-identity" \
    aws sts get-caller-identity

run "availability-zones" \
    aws ec2 describe-availability-zones \
    --region "$REGION"

# ------------------------------------------------
# VPC / NETWORKING
# ------------------------------------------------

run "vpcs" \
    aws ec2 describe-vpcs \
    --region "$REGION"

run "subnets" \
    aws ec2 describe-subnets \
    --region "$REGION"

run "route-tables" \
    aws ec2 describe-route-tables \
    --region "$REGION"

run "internet-gateways" \
    aws ec2 describe-internet-gateways \
    --region "$REGION"

run "nat-gateways" \
    aws ec2 describe-nat-gateways \
    --region "$REGION"

run "elastic-ips" \
    aws ec2 describe-addresses \
    --region "$REGION"

run "network-interfaces" \
    aws ec2 describe-network-interfaces \
    --region "$REGION"

# ------------------------------------------------
# SECURITY
# ------------------------------------------------

run "security-groups" \
    aws ec2 describe-security-groups \
    --region "$REGION"

run "network-acls" \
    aws ec2 describe-network-acls \
    --region "$REGION"

run "vpc-endpoints" \
    aws ec2 describe-vpc-endpoints \
    --region "$REGION"

run "flow-logs" \
    aws ec2 describe-flow-logs \
    --region "$REGION"

# ------------------------------------------------
# LOAD BALANCERS
# ------------------------------------------------

run "load-balancers-v2" \
    aws elbv2 describe-load-balancers \
    --region "$REGION"

run "target-groups" \
    aws elbv2 describe-target-groups \
    --region "$REGION"

run "listeners" \
    aws elbv2 describe-listeners \
    --load-balancer-arn "dummy" \
    --region "$REGION"

# Classic ELB
run "classic-load-balancers" \
    aws elb describe-load-balancers \
    --region "$REGION"

# ------------------------------------------------
# EC2
# ------------------------------------------------

run "ec2-instances" \
    aws ec2 describe-instances \
    --region "$REGION"

run "launch-templates" \
    aws ec2 describe-launch-templates \
    --region "$REGION"

run "key-pairs" \
    aws ec2 describe-key-pairs \
    --region "$REGION"

# ------------------------------------------------
# EKS
# ------------------------------------------------

run "eks-clusters" \
    aws eks list-clusters \
    --region "$REGION"

# ------------------------------------------------
# RDS
# ------------------------------------------------

run "rds-instances" \
    aws rds describe-db-instances \
    --region "$REGION"

run "rds-clusters" \
    aws rds describe-db-clusters \
    --region "$REGION"

run "rds-subnet-groups" \
    aws rds describe-db-subnet-groups \
    --region "$REGION"

# ------------------------------------------------
# ELASTICACHE
# ------------------------------------------------

run "elasticache-clusters" \
    aws elasticache describe-cache-clusters \
    --region "$REGION"

run "elasticache-replication-groups" \
    aws elasticache describe-replication-groups \
    --region "$REGION"

# ------------------------------------------------
# S3
# S3 is global, but inventory it because this is
# an account-wide cleanup.
# ------------------------------------------------

run "s3-buckets" \
    aws s3api list-buckets

# ------------------------------------------------
# ECR
# ------------------------------------------------

run "ecr-repositories" \
    aws ecr describe-repositories \
    --region "$REGION"

# ------------------------------------------------
# TRANSIT GATEWAY
# ------------------------------------------------

run "transit-gateways" \
    aws ec2 describe-transit-gateways \
    --region "$REGION"

run "tgw-attachments" \
    aws ec2 describe-transit-gateway-attachments \
    --region "$REGION"

run "tgw-route-tables" \
    aws ec2 describe-transit-gateway-route-tables \
    --region "$REGION"

run "tgw-routes" \
    aws ec2 search-transit-gateway-routes \
    --transit-gateway-route-table-id \
    tgw-rtb-0c93c9241c859bc3b \
    --filters Name=type,Values=static,propagated \
    --region "$REGION"

# ------------------------------------------------
# VPN
# ------------------------------------------------

run "customer-gateways" \
    aws ec2 describe-customer-gateways \
    --region "$REGION"

run "vpn-connections" \
    aws ec2 describe-vpn-connections \
    --region "$REGION"

run "vpn-gateways" \
    aws ec2 describe-vpn-gateways \
    --region "$REGION"

# ------------------------------------------------
# VPC IPAM
# ------------------------------------------------

run "ipams" \
    aws ec2 describe-ipams \
    --region "$REGION"

run "ipam-pools" \
    aws ec2 describe-ipam-pools \
    --region "$REGION"

run "ipam-pool-cidrs" \
    aws ec2 describe-ipam-pool-cidrs \
    --region "$REGION"

run "ipam-resource-discoveries" \
    aws ec2 describe-ipam-resource-discoveries \
    --region "$REGION"

# ------------------------------------------------
# RAM
# ------------------------------------------------

run "ram-resource-shares" \
    aws ram get-resource-shares \
    --resource-owner SELF \
    --region "$REGION"

# ------------------------------------------------
# CLOUD WAN / NETWORK MANAGER
# ------------------------------------------------

run "core-networks" \
    aws networkmanager list-core-networks \
    --region "$REGION"

run "core-network-policies" \
    aws networkmanager list-core-network-policy-versions \
    --core-network-id core-network-0f8cd58a4424858dc \
    --region "$REGION"

run "network-attachments" \
    aws networkmanager get-transit-gateway-connect-peer \
    --region "$REGION"

# ------------------------------------------------
# CLOUDWATCH
# ------------------------------------------------

run "cloudwatch-alarms" \
    aws cloudwatch describe-alarms \
    --region "$REGION"

# ------------------------------------------------
# LOGGING
# ------------------------------------------------

run "log-groups" \
    aws logs describe-log-groups \
    --region "$REGION"

# ------------------------------------------------
# KMS
# ------------------------------------------------

run "kms-keys" \
    aws kms list-keys \
    --region "$REGION"

run "kms-aliases" \
    aws kms list-aliases \
    --region "$REGION"

# ------------------------------------------------
# SECRETS
# ------------------------------------------------

run "secrets" \
    aws secretsmanager list-secrets \
    --region "$REGION"

# ------------------------------------------------
# SSM
# ------------------------------------------------

run "ssm-documents" \
    aws ssm list-documents \
    --region "$REGION"

# ------------------------------------------------
# LAMBDA
# ------------------------------------------------

run "lambda-functions" \
    aws lambda list-functions \
    --region "$REGION"

# ------------------------------------------------
# DYNAMODB
# ------------------------------------------------

run "dynamodb-tables" \
    aws dynamodb list-tables \
    --region "$REGION"

# ------------------------------------------------
# SNS
# ------------------------------------------------

run "sns-topics" \
    aws sns list-topics \
    --region "$REGION"

# ------------------------------------------------
# SQS
# ------------------------------------------------

run "sqs-queues" \
    aws sqs list-queues \
    --region "$REGION"

# ------------------------------------------------
# RESOURCE GROUPS TAGGING
# ------------------------------------------------

run "tagged-resources" \
    aws resourcegroupstaggingapi get-resources \
    --region "$REGION"

# ------------------------------------------------
# TERRAFORM STATES
# ------------------------------------------------

echo ""
echo ">>> Terraform states"

find ../../terraform -name "terraform.tfstate" -type f \
    > "$OUT/terraform-state-files.txt" 2>&1 || true

echo ""
echo "=============================================="
echo " INVENTORY COMPLETE"
echo "=============================================="
echo "Inventory directory:"
echo "$OUT"
echo ""
echo "Review especially:"
echo "  vpcs.txt"
echo "  subnets.txt"
echo "  nat-gateways.txt"
echo "  network-interfaces.txt"
echo "  tgw-attachments.txt"
echo "  tgw-route-tables.txt"
echo "  ipam-pools.txt"
echo "  ram-resource-shares.txt"
echo "  core-networks.txt"
echo "  ec2-instances.txt"
echo "  load-balancers-v2.txt"
echo "  rds-instances.txt"
echo "  eks-clusters.txt"
echo "=============================================="
