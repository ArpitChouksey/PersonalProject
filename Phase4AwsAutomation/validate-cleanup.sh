i#!/bin/bash

REGION="us-east-1"

echo "========================================="
echo "EKS CLUSTERS"
echo "========================================="
aws eks list-clusters --region $REGION

echo ""
echo "========================================="
echo "EC2 INSTANCES"
echo "========================================="
aws ec2 describe-instances \
--region $REGION \
--filters Name=instance-state-name,Values=running,pending,stopped \
--query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
--output table

echo ""
echo "========================================="
echo "LOAD BALANCERS"
echo "========================================="
aws elbv2 describe-load-balancers \
--region $REGION \
--query 'LoadBalancers[*].[LoadBalancerName,DNSName]' \
--output table

echo ""
echo "========================================="
echo "EBS VOLUMES"
echo "========================================="
aws ec2 describe-volumes \
--region $REGION \
--query 'Volumes[*].[VolumeId,State,Size]' \
--output table

echo ""
echo "========================================="
echo "ECR REPOSITORIES"
echo "========================================="
aws ecr describe-repositories \
--region $REGION \
--query 'repositories[*].[repositoryName]' \
--output table

echo ""
echo "========================================="
echo "NAT GATEWAYS"
echo "========================================="
aws ec2 describe-nat-gateways \
--region $REGION \
--query 'NatGateways[*].[NatGatewayId,State]' \
--output table

echo ""
echo "========================================="
echo "VPCS"
echo "========================================="
aws ec2 describe-vpcs \
--region $REGION \
--query 'Vpcs[*].[VpcId,CidrBlock]' \
--output table

echo ""
echo "========================================="
echo "ELASTIC IPS"
echo "========================================="
aws ec2 describe-addresses \
--region $REGION \
--query 'Addresses[*].[PublicIp]' \
--output table

echo ""
echo "========================================="
echo "CLOUDWATCH LOG GROUPS"
echo "========================================="
aws logs describe-log-groups \
--region $REGION \
--query 'logGroups[*].[logGroupName]' \
--output table

echo ""
echo "========================================="
echo "S3 BUCKETS"
echo "========================================="
aws s3 ls

echo ""
echo "========================================="
echo "RDS DATABASES"
echo "========================================="
aws rds describe-db-instances \
--region $REGION \
--query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' \
--output table

echo ""
echo "========================================="
echo "LAMBDA FUNCTIONS"
echo "========================================="
aws lambda list-functions \
--region $REGION \
--query 'Functions[*].[FunctionName]' \
--output table

echo ""
echo "========================================="
echo "DONE"
echo "========================================="
