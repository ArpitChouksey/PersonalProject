#!/bin/bash

set +e

# ============================================================
# FINAL AWS ZERO-RESOURCE AUDIT
# READ ONLY — NO DELETE / NO MODIFY
# ============================================================

MANAGEMENT_ACCOUNT="211811255273"

ACTIVE_ACCOUNTS=(
  "211811255273"
  "325909447008"
  "152500409784"
  "038269111064"
)

echo
echo "============================================================"
echo "       AWS FINAL ZERO-RESOURCE AUDIT"
echo "============================================================"
echo "READ ONLY — NOTHING WILL BE DELETED"
echo "============================================================"
echo

# ------------------------------------------------------------
# CURRENT IDENTITY
# ------------------------------------------------------------

echo ">>> CURRENT AWS IDENTITY"

aws sts get-caller-identity \
  --query '{Account:Account,Arn:Arn}' \
  --output table

echo


# ------------------------------------------------------------
# REGIONS
# ------------------------------------------------------------

REGIONS=$(aws account list-regions \
  --region us-east-1 \
  --query 'Regions[?RegionOptStatus==`ENABLED`].RegionName' \
  --output text 2>/dev/null)

echo ">>> ENABLED AWS REGIONS"
echo "$REGIONS"
echo


# ============================================================
# ORGANIZATION
# ============================================================

echo
echo "============================================================"
echo "1. AWS ORGANIZATION"
echo "============================================================"

aws organizations describe-organization \
  --query 'Organization.{Id:Id,FeatureSet:FeatureSet,MasterAccountId:MasterAccountId}' \
  --output table 2>/dev/null

echo
echo ">>> ORGANIZATION ACCOUNTS"

aws organizations list-accounts \
  --query 'Accounts[].{Id:Id,Name:Name,Status:Status,JoinedMethod:JoinedMethod}' \
  --output table 2>/dev/null


# ============================================================
# CONTROL TOWER
# ============================================================

echo
echo "============================================================"
echo "2. CONTROL TOWER"
echo "============================================================"

aws controltower list-landing-zones \
  --region us-east-1 \
  --query 'landingZones[].{Arn:arn,Status:status,Version:version}' \
  --output table 2>/dev/null

echo

echo ">>> CONTROL TOWER OPERATIONS"

aws controltower list-landing-zone-operations \
  --region us-east-1 \
  --max-results 20 \
  --query 'landingZoneOperations[].{OperationId:operationIdentifier,Type:operationType,Status:status}' \
  --output table 2>/dev/null


# ============================================================
# IAM IDENTITY CENTER
# ============================================================

echo
echo "============================================================"
echo "3. IAM IDENTITY CENTER"
echo "============================================================"

aws sso-admin list-instances \
  --region us-east-1 \
  --query 'Instances[].{InstanceArn:InstanceArn,IdentityStoreId:IdentityStoreId,Status:Status,Owner:OwnerAccountId}' \
  --output table 2>/dev/null


# ============================================================
# ACCOUNT / REGION RESOURCE AUDIT
# ============================================================

for ACCOUNT in "${ACTIVE_ACCOUNTS[@]}"; do

    echo
    echo
    echo "############################################################"
    echo "# ACCOUNT: $ACCOUNT"
    echo "############################################################"

    # --------------------------------------------------------
    # AUTHENTICATION
    # --------------------------------------------------------

    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN

    if [ "$ACCOUNT" != "$MANAGEMENT_ACCOUNT" ]; then

        CREDS=$(aws sts assume-role \
          --role-arn arn:aws:iam::$ACCOUNT:role/OrganizationAccountAccessRole \
          --role-session-name final-audit \
          --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
          --output text 2>/dev/null)

        if [ -z "$CREDS" ] || [ "$CREDS" = "None" ]; then
            echo
            echo "WARNING: Cannot assume OrganizationAccountAccessRole"
            echo "Skipping account: $ACCOUNT"
            echo
            continue
        fi

        read AK SK ST <<< "$CREDS"

        export AWS_ACCESS_KEY_ID="$AK"
        export AWS_SECRET_ACCESS_KEY="$SK"
        export AWS_SESSION_TOKEN="$ST"
    fi

    aws sts get-caller-identity \
      --query '{Account:Account,Arn:Arn}' \
      --output table

    # ========================================================
    # REGION LOOP
    # ========================================================

    for REGION in $REGIONS; do

        echo
        echo "------------------------------------------------------------"
        echo "ACCOUNT: $ACCOUNT | REGION: $REGION"
        echo "------------------------------------------------------------"

        # ----------------------------------------------------
        # EC2
        # ----------------------------------------------------

        echo "EC2 INSTANCES:"

        aws ec2 describe-instances \
          --region "$REGION" \
          --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Type:InstanceType}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # EBS
        # ----------------------------------------------------

        echo "EBS VOLUMES:"

        aws ec2 describe-volumes \
          --region "$REGION" \
          --filters Name=status,Values=available,in-use \
          --query 'Volumes[].{Id:VolumeId,State:State,Size:Size}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # EBS SNAPSHOTS
        # ----------------------------------------------------

        echo "EBS SNAPSHOTS:"

        aws ec2 describe-snapshots \
          --region "$REGION" \
          --owner-ids self \
          --query 'Snapshots[].{Id:SnapshotId,State:State,Size:VolumeSize}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # NAT
        # ----------------------------------------------------

        echo "NAT GATEWAYS:"

        aws ec2 describe-nat-gateways \
          --region "$REGION" \
          --filter Name=state,Values=pending,available,deleting \
          --query 'NatGateways[].{Id:NatGatewayId,State:State,Vpc:VpcId}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # ELASTIC IP
        # ----------------------------------------------------

        echo "ELASTIC IPs:"

        aws ec2 describe-addresses \
          --region "$REGION" \
          --query 'Addresses[].{AllocationId:AllocationId,AssociationId:AssociationId,PublicIP:PublicIp}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # VPC
        # ----------------------------------------------------

        echo "NON-DEFAULT VPCs:"

        aws ec2 describe-vpcs \
          --region "$REGION" \
          --filters Name=isDefault,Values=false \
          --query 'Vpcs[].{Id:VpcId,CIDR:CidrBlock,State:State}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # SUBNETS
        # ----------------------------------------------------

        echo "NON-DEFAULT VPC SUBNETS:"

        aws ec2 describe-subnets \
          --region "$REGION" \
          --filters Name=default-for-az,Values=false \
          --query 'Subnets[].{Id:SubnetId,Vpc:VpcId,CIDR:CidrBlock,AZ:AvailabilityZone}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # INTERNET GATEWAYS
        # ----------------------------------------------------

        echo "INTERNET GATEWAYS:"

        aws ec2 describe-internet-gateways \
          --region "$REGION" \
          --query 'InternetGateways[].{Id:InternetGatewayId,Attachments:Attachments}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # VPC ENDPOINTS
        # ----------------------------------------------------

        echo "VPC ENDPOINTS:"

        aws ec2 describe-vpc-endpoints \
          --region "$REGION" \
          --query 'VpcEndpoints[].{Id:VpcEndpointId,Type:VpcEndpointType,State:State,Vpc:VpcId}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # LOAD BALANCERS
        # ----------------------------------------------------

        echo "LOAD BALANCERS:"

        aws elbv2 describe-load-balancers \
          --region "$REGION" \
          --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,State:State.Code,ARN:LoadBalancerArn}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # TARGET GROUPS
        # ----------------------------------------------------

        echo "TARGET GROUPS:"

        aws elbv2 describe-target-groups \
          --region "$REGION" \
          --query 'TargetGroups[].{Name:TargetGroupName,Type:TargetType,Protocol:Protocol}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # EKS
        # ----------------------------------------------------

        echo "EKS CLUSTERS:"

        aws eks list-clusters \
          --region "$REGION" \
          --query 'clusters[]' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # RDS
        # ----------------------------------------------------

        echo "RDS INSTANCES:"

        aws rds describe-db-instances \
          --region "$REGION" \
          --query 'DBInstances[].{Id:DBInstanceIdentifier,Status:DBInstanceStatus,Class:DBInstanceClass}' \
          --output table 2>/dev/null

        echo "RDS CLUSTERS:"

        aws rds describe-db-clusters \
          --region "$REGION" \
          --query 'DBClusters[].{Id:DBClusterIdentifier,Status:Status,Engine:Engine}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # ELASTICACHE
        # ----------------------------------------------------

        echo "ELASTICACHE:"

        aws elasticache describe-cache-clusters \
          --region "$REGION" \
          --show-cache-node-info \
          --query 'CacheClusters[].{Id:CacheClusterId,Status:CacheClusterStatus,Engine:Engine}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # MQ
        # ----------------------------------------------------

        echo "AMAZON MQ:"

        aws mq list-brokers \
          --region "$REGION" \
          --query 'BrokerSummaries[].{Id:BrokerId,Name:BrokerName,State:BrokerState}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # VPN
        # ----------------------------------------------------

        echo "VPN CONNECTIONS:"

        aws ec2 describe-vpn-connections \
          --region "$REGION" \
          --query 'VpnConnections[].{Id:VpnConnectionId,State:State,Type:Type}' \
          --output table 2>/dev/null

        echo "CUSTOMER GATEWAYS:"

        aws ec2 describe-customer-gateways \
          --region "$REGION" \
          --query 'CustomerGateways[].{Id:CustomerGatewayId,State:State,Type:Type}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # TRANSIT GATEWAY
        # ----------------------------------------------------

        echo "TRANSIT GATEWAYS:"

        aws ec2 describe-transit-gateways \
          --region "$REGION" \
          --query 'TransitGateways[].{Id:TransitGatewayId,State:State}' \
          --output table 2>/dev/null

        echo "TGW ATTACHMENTS:"

        aws ec2 describe-transit-gateway-attachments \
          --region "$REGION" \
          --query 'TransitGatewayAttachments[].{Id:TransitGatewayAttachmentId,State:State,Type:ResourceType}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # AWS CONFIG
        # ----------------------------------------------------

        echo "CONFIG RECORDERS:"

        aws configservice describe-configuration-recorders \
          --region "$REGION" \
          --query 'ConfigurationRecorders[].{Name:name,Role:roleARN}' \
          --output table 2>/dev/null

        echo "CONFIG DELIVERY CHANNELS:"

        aws configservice describe-delivery-channels \
          --region "$REGION" \
          --query 'DeliveryChannels[].{Name:name,S3Bucket:s3BucketName}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # CLOUDWATCH LOG GROUPS
        # ----------------------------------------------------

        echo "CLOUDWATCH LOG GROUPS:"

        aws logs describe-log-groups \
          --region "$REGION" \
          --query 'logGroups[].{Name:logGroupName,StoredBytes:storedBytes}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # KMS
        # ----------------------------------------------------

        echo "KMS KEYS:"

        aws kms list-keys \
          --region "$REGION" \
          --query 'Keys[].KeyId' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # SECRETS MANAGER
        # ----------------------------------------------------

        echo "SECRETS MANAGER:"

        aws secretsmanager list-secrets \
          --region "$REGION" \
          --query 'SecretList[].{Name:Name,ARN:ARN}' \
          --output table 2>/dev/null

        # ----------------------------------------------------
        # SSM PARAMETER STORE
        # ----------------------------------------------------

        echo "SSM PARAMETERS:"

        aws ssm describe-parameters \
          --region "$REGION" \
          --query 'Parameters[].{Name:Name,Type:Type}' \
          --output table 2>/dev/null

    done

    # ========================================================
    # GLOBAL / REGIONAL SERVICES
    # ========================================================

    echo
    echo "------------------------------------------------------------"
    echo "ACCOUNT $ACCOUNT | GLOBAL RESOURCE CHECK"
    echo "------------------------------------------------------------"

    echo "S3 BUCKETS:"

    aws s3api list-buckets \
      --query 'Buckets[].{Name:Name,Created:CreationDate}' \
      --output table 2>/dev/null

    echo "CLOUDFRONT DISTRIBUTIONS:"

    aws cloudfront list-distributions \
      --query 'DistributionList.Items[].{Id:Id,Status:Status,Domain:DomainName}' \
      --output table 2>/dev/null

    echo "ROUTE53 HOSTED ZONES:"

    aws route53 list-hosted-zones \
      --query 'HostedZones[].{Id:Id,Name:Name,Private:Config.PrivateZone}' \
      --output table 2>/dev/null

    echo "IAM CONTROL TOWER ROLES:"

    aws iam list-roles \
      --query 'Roles[?contains(RoleName, `AWSControlTower`)].RoleName' \
      --output table 2>/dev/null

done


# ============================================================
# MANAGEMENT-SPECIFIC NETWORK MANAGER
# ============================================================

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

echo
echo
echo "============================================================"
echo "4. CLOUD WAN / NETWORK MANAGER GLOBAL CHECK"
echo "============================================================"

for ACCOUNT in "${ACTIVE_ACCOUNTS[@]}"; do

    echo
    echo "ACCOUNT: $ACCOUNT"

    if [ "$ACCOUNT" = "$MANAGEMENT_ACCOUNT" ]; then

        aws networkmanager describe-global-networks \
          --query 'GlobalNetworks[].{Id:GlobalNetworkId,State:State,Description:Description}' \
          --output table 2>/dev/null

    else

        CREDS=$(aws sts assume-role \
          --role-arn arn:aws:iam::$ACCOUNT:role/OrganizationAccountAccessRole \
          --role-session-name networkmanager-audit \
          --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
          --output text 2>/dev/null)

        if [ -n "$CREDS" ] && [ "$CREDS" != "None" ]; then

            read AK SK ST <<< "$CREDS"

            AWS_ACCESS_KEY_ID="$AK" \
            AWS_SECRET_ACCESS_KEY="$SK" \
            AWS_SESSION_TOKEN="$ST" \
            aws networkmanager describe-global-networks \
              --query 'GlobalNetworks[].{Id:GlobalNetworkId,State:State,Description:Description}' \
              --output table 2>/dev/null
        else
            echo "Cannot access account."
        fi
    fi
done


# ============================================================
# FINAL
# ============================================================

echo
echo
echo "============================================================"
echo "              FINAL AUDIT COMPLETED"
echo "============================================================"
echo
echo "IMPORTANT:"
echo "This script is READ ONLY."
echo "No AWS resources were deleted."
echo "No Terraform files were modified."
echo "No accounts were closed."
echo
echo "Review every non-empty resource section above."
echo "============================================================"

