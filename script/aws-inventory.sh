#!/bin/bash

REGION="us-east-1"
VPC_ID="vpc-03afaff7b0e91ddeb"
CLUSTER_NAME="private-eks-platform"

echo "============================================================"
echo " PRIVATE EKS PLATFORM - AWS INVENTORY"
echo "============================================================"
echo "Region : $REGION"
echo "VPC    : $VPC_ID"
echo "Cluster: $CLUSTER_NAME"
echo "============================================================"


# ------------------------------------------------------------
# ACCOUNT
# ------------------------------------------------------------

echo
echo "==================== AWS ACCOUNT ===================="

aws sts get-caller-identity


# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

echo
echo "==================== VPC ===================="

aws ec2 describe-vpcs \
  --vpc-ids "$VPC_ID" \
  --region "$REGION" \
  --query 'Vpcs[].{
    VpcId:VpcId,
    CIDR:CidrBlock,
    State:State,
    DhcpOptionsId:DhcpOptionsId,
    Tags:Tags
  }'


# ------------------------------------------------------------
# SUBNETS
# ------------------------------------------------------------

echo
echo "==================== SUBNETS ===================="

aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'Subnets[].{
    SubnetId:SubnetId,
    AZ:AvailabilityZone,
    CIDR:CidrBlock,
    AvailableIPs:AvailableIpAddressCount,
    MapPublicIP:MapPublicIpOnLaunch,
    State:State,
    Tags:Tags
  }'


# ------------------------------------------------------------
# INTERNET GATEWAY
# ------------------------------------------------------------

echo
echo "==================== INTERNET GATEWAY ===================="

aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'InternetGateways[].{
    InternetGatewayId:InternetGatewayId,
    State:Attachments[0].State,
    Tags:Tags
  }'


# ------------------------------------------------------------
# ROUTE TABLES
# ------------------------------------------------------------

echo
echo "==================== ROUTE TABLES ===================="

aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'RouteTables[].{
    RouteTableId:RouteTableId,
    Routes:Routes,
    Associations:Associations,
    Tags:Tags
  }'


# ------------------------------------------------------------
# VPC ENDPOINTS
# ------------------------------------------------------------

echo
echo "==================== VPC ENDPOINTS ===================="

aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'VpcEndpoints[].{
    EndpointId:VpcEndpointId,
    Service:ServiceName,
    Type:VpcEndpointType,
    State:State,
    PrivateDNS:PrivateDnsEnabled,
    Subnets:SubnetIds,
    RouteTables:RouteTableIds,
    NetworkInterfaces:NetworkInterfaceIds,
    Groups:Groups
  }'


# ------------------------------------------------------------
# VPC ENDPOINT NETWORK INTERFACES
# ------------------------------------------------------------

echo
echo "==================== ENDPOINT ENIs ===================="

ENDPOINT_ENIS=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'VpcEndpoints[].NetworkInterfaceIds[]' \
  --output text)

if [ -n "$ENDPOINT_ENIS" ]; then

  aws ec2 describe-network-interfaces \
    --network-interface-ids $ENDPOINT_ENIS \
    --region "$REGION" \
    --query 'NetworkInterfaces[].{
      ENI:NetworkInterfaceId,
      PrivateIP:PrivateIpAddress,
      Subnet:SubnetId,
      AZ:AvailabilityZone,
      Description:Description,
      Groups:Groups
    }'

fi


# ------------------------------------------------------------
# SECURITY GROUPS
# ------------------------------------------------------------

echo
echo "==================== SECURITY GROUPS ===================="

aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'SecurityGroups[].{
    GroupId:GroupId,
    Name:GroupName,
    Description:Description,
    Inbound:IpPermissions,
    Outbound:IpPermissionsEgress,
    Tags:Tags
  }'


# ------------------------------------------------------------
# VPC DNS
# ------------------------------------------------------------

echo
echo "==================== VPC DNS ===================="

aws ec2 describe-vpc-attribute \
  --vpc-id "$VPC_ID" \
  --attribute enableDnsSupport \
  --region "$REGION"

aws ec2 describe-vpc-attribute \
  --vpc-id "$VPC_ID" \
  --attribute enableDnsHostnames \
  --region "$REGION"


# ------------------------------------------------------------
# DHCP OPTIONS
# ------------------------------------------------------------

echo
echo "==================== DHCP OPTIONS ===================="

DHCP_ID=$(aws ec2 describe-vpcs \
  --vpc-ids "$VPC_ID" \
  --region "$REGION" \
  --query 'Vpcs[0].DhcpOptionsId' \
  --output text)

aws ec2 describe-dhcp-options \
  --dhcp-options-ids "$DHCP_ID" \
  --region "$REGION"


# ------------------------------------------------------------
# VPC FLOW LOGS
# ------------------------------------------------------------

echo
echo "==================== VPC FLOW LOGS ===================="

aws ec2 describe-flow-logs \
  --filter "Name=resource-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'FlowLogs[].{
    FlowLogId:FlowLogId,
    ResourceId:ResourceId,
    TrafficType:TrafficType,
    LogDestination:LogDestination,
    LogDestinationType:LogDestinationType,
    Status:FlowLogStatus
  }'


# ------------------------------------------------------------
# EKS CLUSTER
# ------------------------------------------------------------

echo
echo "==================== EKS CLUSTER ===================="

aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'cluster.{
    Name:name,
    Status:status,
    Version:version,
    ARN:arn,
    RoleArn:roleArn,
    Endpoint:endpoint,
    EndpointPublic:resourcesVpcConfig.endpointPublicAccess,
    EndpointPrivate:resourcesVpcConfig.endpointPrivateAccess,
    ClusterSecurityGroup:resourcesVpcConfig.clusterSecurityGroupId,
    SecurityGroups:resourcesVpcConfig.securityGroupIds,
    Subnets:resourcesVpcConfig.subnetIds,
    VPC:resourcesVpcConfig.vpcId,
    AuthMode:accessConfig.authenticationMode,
    PlatformVersion:platformVersion
  }'


# ------------------------------------------------------------
# EKS NODE GROUPS
# ------------------------------------------------------------

echo
echo "==================== EKS NODE GROUPS ===================="

NODE_GROUPS=$(aws eks list-nodegroups \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'nodegroups[]' \
  --output text)

if [ -n "$NODE_GROUPS" ]; then

  for NG in $NODE_GROUPS
  do

    echo
    echo "---------- NODE GROUP: $NG ----------"

    aws eks describe-nodegroup \
      --cluster-name "$CLUSTER_NAME" \
      --nodegroup-name "$NG" \
      --region "$REGION" \
      --query 'nodegroup.{
        Name:nodegroupName,
        Status:status,
        Version:version,
        ReleaseVersion:releaseVersion,
        NodeRole:nodeRole,
        Subnets:subnets,
        InstanceTypes:instanceTypes,
        CapacityType:capacityType,
        AMIType:amiType,
        ScalingConfig:scalingConfig,
        DiskSize:diskSize,
        RemoteAccess:remoteAccess,
        Health:health
      }'

  done

else

  echo "No active node groups found."

fi


# ------------------------------------------------------------
# EKS ADDONS
# ------------------------------------------------------------

echo
echo "==================== EKS ADDONS ===================="

aws eks list-addons \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION"

for ADDON in $(aws eks list-addons \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'addons[]' \
  --output text)
do

  echo
  echo "---------- ADDON: $ADDON ----------"

  aws eks describe-addon \
    --cluster-name "$CLUSTER_NAME" \
    --addon-name "$ADDON" \
    --region "$REGION" \
    --query 'addon.{
      Name:addonName,
      Status:status,
      Version:addonVersion,
      ServiceAccount:serviceAccountRoleArn
    }'

done


# ------------------------------------------------------------
# EKS POD IDENTITY ASSOCIATIONS
# ------------------------------------------------------------

echo
echo "==================== POD IDENTITY ===================="

aws eks list-pod-identity-associations \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION"


# ------------------------------------------------------------
# IAM ROLES
# ------------------------------------------------------------

echo
echo "==================== IAM ROLES ===================="

echo
echo "---- EKS Cluster Role ----"

aws iam get-role \
  --role-name eks-private-cluster-role \
  --query 'Role.{
    RoleName:RoleName,
    ARN:Arn,
    TrustPolicy:AssumeRolePolicyDocument
  }'


echo
echo "---- EKS Node Role ----"

aws iam get-role \
  --role-name eks-private-node-role \
  --query 'Role.{
    RoleName:RoleName,
    ARN:Arn,
    TrustPolicy:AssumeRolePolicyDocument
  }'


echo
echo "---- Secret Reader Role ----"

aws iam get-role \
  --role-name eks-secret-reader-role \
  --query 'Role.{
    RoleName:RoleName,
    ARN:Arn,
    TrustPolicy:AssumeRolePolicyDocument
  }'


# ------------------------------------------------------------
# IAM ATTACHED POLICIES
# ------------------------------------------------------------

echo
echo "==================== IAM POLICIES ===================="

for ROLE in \
  eks-private-cluster-role \
  eks-private-node-role \
  eks-secret-reader-role
do

  echo
  echo "---------- ROLE: $ROLE ----------"

  echo "Managed Policies:"

  aws iam list-attached-role-policies \
    --role-name "$ROLE" \
    --query 'AttachedPolicies[].{
      Name:PolicyName,
      ARN:PolicyArn
    }'

  echo
  echo "Inline Policies:"

  aws iam list-role-policies \
    --role-name "$ROLE"

done


# ------------------------------------------------------------
# KMS
# ------------------------------------------------------------

echo
echo "==================== KMS ===================="

aws kms list-aliases \
  --region "$REGION" \
  --query 'Aliases[?AliasName==`alias/private-eks-platform-secrets`].{
    Alias:AliasName,
    TargetKeyId:TargetKeyId
  }'


KMS_KEY_ID=$(aws kms list-aliases \
  --region "$REGION" \
  --query 'Aliases[?AliasName==`alias/private-eks-platform-secrets`].TargetKeyId' \
  --output text)

if [ -n "$KMS_KEY_ID" ]; then

  aws kms describe-key \
    --key-id "$KMS_KEY_ID" \
    --region "$REGION" \
    --query 'KeyMetadata.{
      KeyId:KeyId,
      ARN:Arn,
      Description:Description,
      State:KeyState,
      KeyUsage:KeyUsage,
      KeySpec:KeySpec
    }'

fi


# ------------------------------------------------------------
# SECRETS MANAGER
# ------------------------------------------------------------

echo
echo "==================== SECRETS MANAGER ===================="

aws secretsmanager describe-secret \
  --secret-id "private-eks-platform/app/test" \
  --region "$REGION" \
  --query '{
    Name:Name,
    ARN:ARN,
    Description:Description,
    KMSKeyId:KmsKeyId,
    RotationEnabled:RotationEnabled,
    CreatedDate:CreatedDate,
    LastChangedDate:LastChangedDate
  }'


# ------------------------------------------------------------
# ECR
# ------------------------------------------------------------

echo
echo "==================== ECR REPOSITORIES ===================="

aws ecr describe-repositories \
  --region "$REGION" \
  --query 'repositories[].{
    RepositoryName:repositoryName,
    URI:repositoryUri,
    ARN:repositoryArn,
    Encryption:encryptionConfiguration,
    ScanOnPush:imageScanningConfiguration.scanOnPush
  }'


echo
echo "==================== ECR IMAGES ===================="

for REPO in $(aws ecr describe-repositories \
  --region "$REGION" \
  --query 'repositories[].repositoryName' \
  --output text)
do

  echo
  echo "---------- REPOSITORY: $REPO ----------"

  aws ecr describe-images \
    --repository-name "$REPO" \
    --region "$REGION" \
    --query 'imageDetails[].{
      Tags:imageTags,
      Digest:imageDigest,
      Pushed:imagePushedAt,
      Size:imageSizeInBytes,
      MediaType:imageManifestMediaType
    }'

done


# ------------------------------------------------------------
# END
# ------------------------------------------------------------

echo
echo "============================================================"
echo " INVENTORY COMPLETE"
echo "============================================================"
