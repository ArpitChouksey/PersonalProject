#!/bin/bash

set -u

echo "============================================================"
echo " FINAL AWS MANAGEMENT ACCOUNT ZERO-RESOURCE AUDIT"
echo " READ-ONLY — NO DELETE OPERATIONS"
echo "============================================================"

ACCOUNT_ID=$(aws sts get-caller-identity \
  --query 'Account' \
  --output text)

echo
echo "Account: $ACCOUNT_ID"
echo "Identity:"
aws sts get-caller-identity --output table

echo
echo "============================================================"
echo " 1. ENABLED AWS REGIONS"
echo "============================================================"

REGIONS=$(aws ec2 describe-regions \
  --region us-east-1 \
  --all-regions \
  --query 'Regions[?OptInStatus!=`not-opted-in`].RegionName' \
  --output text)

echo "$REGIONS"

echo
echo "============================================================"
echo " 2. REGIONAL RESOURCE AUDIT"
echo "============================================================"

for REGION in $REGIONS; do

    echo
    echo "############################################################"
    echo " REGION: $REGION"
    echo "############################################################"

    echo
    echo "--- EC2 INSTANCES ---"
    aws ec2 describe-instances \
      --region "$REGION" \
      --query 'Reservations[].Instances[?State.Name!=`terminated`].[InstanceId,State.Name,InstanceType]' \
      --output table

    echo
    echo "--- EBS VOLUMES ---"
    aws ec2 describe-volumes \
      --region "$REGION" \
      --query 'Volumes[?State!=`deleted`].[VolumeId,State,Size,AvailabilityZone]' \
      --output table

    echo
    echo "--- EBS SNAPSHOTS ---"
    aws ec2 describe-snapshots \
      --region "$REGION" \
      --owner-ids "$ACCOUNT_ID" \
      --query 'Snapshots[].{SnapshotId:SnapshotId,State:State,Size:VolumeSize}' \
      --output table

    echo
    echo "--- AMIs ---"
    aws ec2 describe-images \
      --region "$REGION" \
      --owners "$ACCOUNT_ID" \
      --query 'Images[].{ImageId:ImageId,Name:Name,State:State}' \
      --output table

    echo
    echo "--- VPCs ---"
    aws ec2 describe-vpcs \
      --region "$REGION" \
      --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,Default:IsDefault}' \
      --output table

    echo
    echo "--- SUBNETS ---"
    aws ec2 describe-subnets \
      --region "$REGION" \
      --query 'Subnets[].{SubnetId:SubnetId,VpcId:VpcId,Cidr:CidrBlock}' \
      --output table

    echo
    echo "--- INTERNET GATEWAYS ---"
    aws ec2 describe-internet-gateways \
      --region "$REGION" \
      --query 'InternetGateways[].{IGW:InternetGatewayId,Vpc:Attachments[0].VpcId,State:Attachments[0].State}' \
      --output table

    echo
    echo "--- NAT GATEWAYS ---"
    aws ec2 describe-nat-gateways \
      --region "$REGION" \
      --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State,VpcId]' \
      --output table

    echo
    echo "--- ELASTIC IPs ---"
    aws ec2 describe-addresses \
      --region "$REGION" \
      --query 'Addresses[].{AllocationId:AllocationId,PublicIp:PublicIp,AssociationId:AssociationId}' \
      --output table

    echo
    echo "--- VPC ENDPOINTS ---"
    aws ec2 describe-vpc-endpoints \
      --region "$REGION" \
      --query 'VpcEndpoints[].{Id:VpcEndpointId,State:State,Vpc:VpcId,Service:ServiceName}' \
      --output table

    echo
    echo "--- ROUTE TABLES ---"
    aws ec2 describe-route-tables \
      --region "$REGION" \
      --query 'RouteTables[].{RouteTableId:RouteTableId,VpcId:VpcId}' \
      --output table

    echo
    echo "--- NETWORK INTERFACES ---"
    aws ec2 describe-network-interfaces \
      --region "$REGION" \
      --query 'NetworkInterfaces[].{ENI:NetworkInterfaceId,Status:Status,Vpc:VpcId,Description:Description}' \
      --output table

    echo
    echo "--- TRANSIT GATEWAYS ---"
    aws ec2 describe-transit-gateways \
      --region "$REGION" \
      --query 'TransitGateways[].{Id:TransitGatewayId,State:State}' \
      --output table

    echo
    echo "--- TRANSIT GATEWAY ATTACHMENTS ---"
    aws ec2 describe-transit-gateway-attachments \
      --region "$REGION" \
      --query 'TransitGatewayAttachments[].{Id:TransitGatewayAttachmentId,State:State,Type:ResourceType}' \
      --output table

    echo
    echo "--- VPN CONNECTIONS ---"
    aws ec2 describe-vpn-connections \
      --region "$REGION" \
      --query 'VpnConnections[].{Id:VpnConnectionId,State:State,Type:Type}' \
      --output table

    echo
    echo "--- CUSTOMER GATEWAYS ---"
    aws ec2 describe-customer-gateways \
      --region "$REGION" \
      --query 'CustomerGateways[].{Id:CustomerGatewayId,State:State,Type:Type}' \
      --output table

    echo
    echo "--- LOAD BALANCERS ---"
    aws elbv2 describe-load-balancers \
      --region "$REGION" \
      --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,State:State.Code,ARN:LoadBalancerArn}' \
      --output table

    echo
    echo "--- EKS CLUSTERS ---"
    aws eks list-clusters \
      --region "$REGION" \
      --output table

    echo
    echo "--- RDS INSTANCES ---"
    aws rds describe-db-instances \
      --region "$REGION" \
      --query 'DBInstances[].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine}' \
      --output table

    echo
    echo "--- RDS CLUSTERS ---"
    aws rds describe-db-clusters \
      --region "$REGION" \
      --query 'DBClusters[].{Identifier:DBClusterIdentifier,Status:Status,Engine:Engine}' \
      --output table

    echo
    echo "--- ELASTICACHE ---"
    aws elasticache describe-cache-clusters \
      --region "$REGION" \
      --query 'CacheClusters[].{Id:CacheClusterId,Status:CacheClusterStatus,Engine:Engine}' \
      --output table

    echo
    echo "--- OPENSEARCH ---"
    aws opensearch list-domain-names \
      --region "$REGION" \
      --query 'DomainNames[].DomainName' \
      --output table

    echo
    echo "--- ECS CLUSTERS ---"
    aws ecs list-clusters \
      --region "$REGION" \
      --output table

    echo
    echo "--- LAMBDA FUNCTIONS ---"
    aws lambda list-functions \
      --region "$REGION" \
      --query 'Functions[].{Name:FunctionName,Runtime:Runtime}' \
      --output table

    echo
    echo "--- API GATEWAYS ---"
    aws apigateway get-rest-apis \
      --region "$REGION" \
      --query 'items[].{Id:id,Name:name}' \
      --output table

    echo
    echo "--- SQS QUEUES ---"
    aws sqs list-queues \
      --region "$REGION" \
      --output table

    echo
    echo "--- SNS TOPICS ---"
    aws sns list-topics \
      --region "$REGION" \
      --query 'Topics[].TopicArn' \
      --output table

    echo
    echo "--- MQ BROKERS ---"
    aws mq list-brokers \
      --region "$REGION" \
      --query 'BrokerSummaries[].{Id:BrokerId,Name:BrokerName,Status:BrokerState}' \
      --output table

    echo
    echo "--- EFS ---"
    aws efs describe-file-systems \
      --region "$REGION" \
      --query 'FileSystems[].{Id:FileSystemId,State:LifeCycleState,Size:SizeInBytes.Value}' \
      --output table

    echo
    echo "--- FSx ---"
    aws fsx describe-file-systems \
      --region "$REGION" \
      --query 'FileSystems[].{Id:FileSystemId,Type:FileSystemType,Lifecycle:Lifecycle}' \
      --output table

    echo
    echo "--- SECRETS MANAGER ---"
    aws secretsmanager list-secrets \
      --region "$REGION" \
      --query 'SecretList[].{Name:Name,ARN:ARN}' \
      --output table

    echo
    echo "--- SSM PARAMETERS ---"
    aws ssm describe-parameters \
      --region "$REGION" \
      --query 'Parameters[].{Name:Name,Type:Type}' \
      --output table

    echo
    echo "--- CLOUDWATCH LOG GROUPS ---"
    aws logs describe-log-groups \
      --region "$REGION" \
      --query 'logGroups[].{Name:logGroupName,StoredBytes:storedBytes}' \
      --output table

    echo
    echo "--- AWS CONFIG ---"
    aws configservice describe-configuration-recorders \
      --region "$REGION" \
      --output table

    echo
    echo "--- CONFIG DELIVERY CHANNELS ---"
    aws configservice describe-delivery-channels \
      --region "$REGION" \
      --output table

    echo
    echo "--- KMS KEYS ---"
    aws kms list-keys \
      --region "$REGION" \
      --output table

done

echo
echo "============================================================"
echo " 3. GLOBAL SERVICES"
echo "============================================================"

echo
echo "--- S3 BUCKETS ---"
aws s3api list-buckets \
  --query 'Buckets[].{Name:Name,Created:CreationDate}' \
  --output table

echo
echo "--- CLOUDFRONT DISTRIBUTIONS ---"
aws cloudfront list-distributions \
  --query 'DistributionList.Items[].{Id:Id,Status:Status,Domain:DomainName}' \
  --output table

echo
echo "--- ROUTE53 HOSTED ZONES ---"
aws route53 list-hosted-zones \
  --query 'HostedZones[].{Id:Id,Name:Name,Private:Config.PrivateZone}' \
  --output table

echo
echo "--- ROUTE53 TRAFFIC POLICIES ---"
aws route53 list-traffic-policies \
  --query 'TrafficPolicySummaries[].{Id:Id,Name:Name,Version:Version}' \
  --output table

echo
echo "--- IAM CONTROL TOWER ROLES ---"
aws iam list-roles \
  --query 'Roles[?starts_with(RoleName, `AWSControlTower`)].RoleName' \
  --output table

echo
echo "--- IAM POLICIES WITH CONTROL TOWER NAME ---"
aws iam list-policies \
  --scope Local \
  --query 'Policies[?contains(PolicyName, `ControlTower`)].{Name:PolicyName,ARN:Arn}' \
  --output table

echo
echo "--- CLOUDTRAIL ---"
aws cloudtrail describe-trails \
  --include-shadow-trails \
  --query 'trailList[].{Name:Name,HomeRegion:HomeRegion,MultiRegion:IsMultiRegionTrail,LogFileValidation:LogFileValidationEnabled}' \
  --output table

echo
echo "--- CLOUDTRAIL TRAIL STATUS ---"
for TRAIL in $(aws cloudtrail describe-trails \
  --query 'trailList[].Name' \
  --output text); do
    aws cloudtrail get-trail-status \
      --name "$TRAIL" \
      --query '{Trail:LatestCloudWatchLogsDeliveryTime,S3:LatestDeliveryTime,IsLogging:IsLogging}' \
      --output table
done

echo
echo "--- BACKUP VAULTS ---"
aws backup list-backup-vaults \
  --query 'BackupVaultList[].{Name:BackupVaultName,ARN:BackupVaultArn}' \
  --output table

echo
echo "--- NETWORK MANAGER / CLOUD WAN ---"
aws networkmanager describe-global-networks \
  --query 'GlobalNetworks[].{Id:GlobalNetworkId,State:State,Description:Description}' \
  --output table

echo
echo "--- IAM IDENTITY CENTER ---"
aws sso-admin list-instances \
  --region us-east-1 \
  --query 'Instances[].{ARN:InstanceArn,Status:Status,IdentityStore:IdentityStoreId}' \
  --output table

echo
echo "--- ORGANIZATION ---"
aws organizations describe-organization \
  --query 'Organization.{Id:Id,MasterAccountId:MasterAccountId,FeatureSet:FeatureSet}' \
  --output table

echo
echo "--- ORGANIZATION ACCOUNTS ---"
aws organizations list-accounts \
  --query 'Accounts[].{Id:Id,Name:Name,Status:Status}' \
  --output table

echo
echo "============================================================"
echo " AUDIT COMPLETED"
echo "============================================================"
echo "Review any NON-EMPTY sections above."
echo "Default VPCs, default route tables, default security groups,"
echo "AWS-managed KMS keys, and AWS service-created log groups"
echo "do not automatically mean billable customer resources."
echo "============================================================"

