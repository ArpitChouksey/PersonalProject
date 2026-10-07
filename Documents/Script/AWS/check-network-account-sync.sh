#!/bin/bash

set -u

# ============================================================
# AWS NETWORK ACCOUNT INVENTORY / HEALTH CHECK
# ============================================================
#
# Purpose:
#   Inventory and validate the AWS Network Account independently
#   of Terraform.
#
# IMPORTANT:
#   This script does NOT read Terraform state.
#   It only checks the actual AWS environment.
#
# ============================================================

AWS_PROFILE="network"
AWS_REGION="us-east-1"

VPC_ID="vpc-0e0311231e766e555"
TGW_ID="tgw-0a8bb2ec2e645f5ad"

VPN_ID_01="vpn-09661d881516baf0f"
VPN_ID_02="vpn-0941751367b0ed511"

CGW_ID_01="cgw-0635c05f23a4a6fa2"
CGW_ID_02="cgw-0f99e4fe52a311587"

EXPECTED_ACCOUNT_ID="360734036001"

export AWS_PROFILE
export AWS_REGION

# ============================================================
# COLORS
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# ============================================================
# FUNCTIONS
# ============================================================

print_header() {
    echo
    echo "============================================================"
    echo -e "${CYAN}$1${NC}"
    echo "============================================================"
    echo
}

print_section() {
    echo
    echo "------------------------------------------------------------"
    echo -e "${BLUE}$1${NC}"
    echo "------------------------------------------------------------"
    echo
}

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

check_command() {

    if ! command -v aws >/dev/null 2>&1; then
        echo
        echo -e "${RED}[ERROR] AWS CLI is not installed or not in PATH.${NC}"
        exit 1
    fi
}

# ============================================================
# START
# ============================================================

clear

print_header "AWS NETWORK ACCOUNT INVENTORY / HEALTH CHECK"

echo "AWS Profile : ${AWS_PROFILE}"
echo "Region      : ${AWS_REGION}"
echo "VPC         : ${VPC_ID}"
echo "TGW         : ${TGW_ID}"

check_command

# ============================================================
# 1. AWS ACCOUNT
# ============================================================

print_section "1. AWS ACCOUNT"

ACCOUNT_ID=$(aws sts get-caller-identity \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --query 'Account' \
    --output text 2>/dev/null || true)

if [[ -z "${ACCOUNT_ID}" || "${ACCOUNT_ID}" == "None" ]]; then
    fail "Unable to identify AWS account using profile '${AWS_PROFILE}'"
    echo
    echo "Run:"
    echo "  aws configure list-profiles"
    echo
    echo "Then:"
    echo "  aws sts get-caller-identity --profile ${AWS_PROFILE}"
    exit 1
fi

if [[ "${ACCOUNT_ID}" == "${EXPECTED_ACCOUNT_ID}" ]]; then
    pass "AWS Account ID: ${ACCOUNT_ID}"
else
    fail "Unexpected AWS Account ID: ${ACCOUNT_ID}"
    echo "Expected: ${EXPECTED_ACCOUNT_ID}"
fi

CALLER_ARN=$(aws sts get-caller-identity \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --query 'Arn' \
    --output text)

echo "Caller ARN : ${CALLER_ARN}"

# ============================================================
# 2. VPC
# ============================================================

print_section "2. VPC"

VPC_DATA=$(aws ec2 describe-vpcs \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --vpc-ids "${VPC_ID}" \
    --query 'Vpcs[0].[VpcId,CidrBlock,State,IsDefault]' \
    --output text 2>/dev/null || true)

if [[ -n "${VPC_DATA}" ]]; then
    echo "${VPC_DATA}"
    pass "Network VPC exists: ${VPC_ID}"
else
    fail "Network VPC not found: ${VPC_ID}"
fi

# ============================================================
# 3. INTERNET GATEWAY
# ============================================================

print_section "3. INTERNET GATEWAY"

IGW_DATA=$(aws ec2 describe-internet-gateways \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filters "Name=attachment.vpc-id,Values=${VPC_ID}" \
    --query 'InternetGateways[*].[InternetGatewayId,State,Tags[?Key==`Name`].Value|[0]]' \
    --output table 2>/dev/null || true)

if [[ -n "${IGW_DATA}" ]]; then
    echo "${IGW_DATA}"
    pass "Internet Gateway attached to Network VPC"
else
    warn "No Internet Gateway found attached to ${VPC_ID}"
fi

# ============================================================
# 4. SUBNETS
# ============================================================

print_section "4. SUBNETS"

SUBNET_DATA=$(aws ec2 describe-subnets \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,State,MapPublicIpOnLaunch,Tags[?Key==`Name`].Value|[0]]' \
    --output table 2>/dev/null || true)

if [[ -n "${SUBNET_DATA}" ]]; then
    echo "${SUBNET_DATA}"
    pass "Subnets discovered in Network VPC"
else
    fail "No subnets found in ${VPC_ID}"
fi

# ============================================================
# 5. ROUTE TABLES
# ============================================================

print_section "5. ROUTE TABLES"

RT_DATA=$(aws ec2 describe-route-tables \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'RouteTables[*].[RouteTableId,Associations[0].Main,Tags[?Key==`Name`].Value|[0]]' \
    --output table 2>/dev/null || true)

if [[ -n "${RT_DATA}" ]]; then
    echo "${RT_DATA}"
    pass "Route tables discovered"
else
    fail "No route tables found"
fi

# ============================================================
# 6. VPC ROUTE TO AZURE
# ============================================================

print_section "6. VPC ROUTE TO AZURE"

AZURE_ROUTE_FOUND=0

ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'RouteTables[*].RouteTableId' \
    --output text)

for RT_ID in ${ROUTE_TABLE_IDS}; do

    ROUTE=$(aws ec2 describe-route-tables \
        --profile "${AWS_PROFILE}" \
        --region "${AWS_REGION}" \
        --route-table-ids "${RT_ID}" \
        --query 'RouteTables[0].Routes[?DestinationCidrBlock==`10.20.0.0/16`].[DestinationCidrBlock,TransitGatewayId,State]' \
        --output text 2>/dev/null || true)

    if [[ -n "${ROUTE}" ]]; then
        echo "Route Table: ${RT_ID}"
        echo "${ROUTE}"
        AZURE_ROUTE_FOUND=1
    fi

done

if [[ "${AZURE_ROUTE_FOUND}" -eq 1 ]]; then
    pass "Route to Azure 10.20.0.0/16 exists"
else
    fail "Route to Azure 10.20.0.0/16 not found"
fi

# ============================================================
# 7. NAT GATEWAYS
# ============================================================

print_section "7. NAT GATEWAYS"

NAT_DATA=$(aws ec2 describe-nat-gateways \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filter "Name=vpc-id,Values=${VPC_ID}" \
             "Name=state,Values=available" \
    --query 'NatGateways[*].[NatGatewayId,SubnetId,ConnectivityType,State,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
    --output table 2>/dev/null || true)

if [[ -n "${NAT_DATA}" ]]; then
    echo "${NAT_DATA}"
    pass "Available NAT Gateway(s) found"
else
    warn "No available NAT Gateway found"
fi

# ============================================================
# 8. ELASTIC IPS
# ============================================================

print_section "8. ELASTIC IPS"

EIP_DATA=$(aws ec2 describe-addresses \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --query 'Addresses[*].[AllocationId,PublicIp,AssociationId,NetworkInterfaceId,Tags[?Key==`Name`].Value|[0]]' \
    --output table 2>/dev/null || true)

if [[ -n "${EIP_DATA}" ]]; then
    echo "${EIP_DATA}"
    pass "Elastic IP inventory retrieved"
else
    warn "No Elastic IPs found"
fi

# ============================================================
# 9. VPC IPAM
# ============================================================

print_section "9. VPC IPAM"

IPAM_DATA=$(aws ec2 describe-ipams \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --query 'Ipams[*].[IpamId,State,PrivateDefaultScopeId,PublicDefaultScopeId,Description]' \
    --output table 2>/dev/null || true)

if [[ -n "${IPAM_DATA}" ]]; then
    echo "${IPAM_DATA}"
    pass "VPC IPAM inventory retrieved"
else
    warn "No VPC IPAM found"
fi

# ============================================================
# 10. IPAM POOLS
# ============================================================

print_section "10. IPAM POOLS"

POOL_DATA=$(aws ec2 describe-ipam-pools \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --query 'IpamPools[*].[IpamPoolId,IpamScopeId,AddressFamily,State,Locale,Description]' \
    --output table 2>/dev/null || true)

if [[ -n "${POOL_DATA}" ]]; then
    echo "${POOL_DATA}"
    pass "IPAM pools discovered"
else
    warn "No IPAM pools found"
fi

# ============================================================
# 11. TRANSIT GATEWAY
# ============================================================

print_section "11. TRANSIT GATEWAY"

TGW_DATA=$(aws ec2 describe-transit-gateways \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --transit-gateway-ids "${TGW_ID}" \
    --query 'TransitGateways[0].[TransitGatewayId,State,OwnerId,AmazonSideAsn,DefaultRouteTableId]' \
    --output table 2>/dev/null || true)

if [[ -n "${TGW_DATA}" ]]; then
    echo "${TGW_DATA}"
    pass "Transit Gateway exists: ${TGW_ID}"
else
    fail "Transit Gateway not found: ${TGW_ID}"
fi

# ============================================================
# 12. TGW ROUTE TABLES
# ============================================================

print_section "12. TGW ROUTE TABLES"

TGW_RT_DATA=$(aws ec2 describe-transit-gateway-route-tables \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filters "Name=transit-gateway-id,Values=${TGW_ID}" \
    --query 'TransitGatewayRouteTables[*].[TransitGatewayRouteTableId,State,DefaultAssociationRouteTable,DefaultPropagationRouteTable,Tags[?Key==`Name`].Value|[0]]' \
    --output table 2>/dev/null || true)

if [[ -n "${TGW_RT_DATA}" ]]; then
    echo "${TGW_RT_DATA}"
    pass "TGW route tables discovered"
else
    fail "No TGW route tables found"
fi

# ============================================================
# 13. TGW ATTACHMENTS
# ============================================================

print_section "13. TGW ATTACHMENTS"

TGW_ATTACH_DATA=$(aws ec2 describe-transit-gateway-attachments \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filters "Name=transit-gateway-id,Values=${TGW_ID}" \
    --query 'TransitGatewayAttachments[*].[TransitGatewayAttachmentId,ResourceType,ResourceId,State,TransitGatewayOwnerId]' \
    --output table 2>/dev/null || true)

if [[ -n "${TGW_ATTACH_DATA}" ]]; then
    echo "${TGW_ATTACH_DATA}"
    pass "TGW attachments discovered"
else
    fail "No TGW attachments found"
fi

# ============================================================
# 14. CUSTOMER GATEWAYS
# ============================================================

print_section "14. CUSTOMER GATEWAYS"

CGW_DATA=$(aws ec2 describe-customer-gateways \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --customer-gateway-ids "${CGW_ID_01}" "${CGW_ID_02}" \
    --query 'CustomerGateways[*].[CustomerGatewayId,State,Type,BgpAsn,IpAddress]' \
    --output table 2>/dev/null || true)

if [[ -n "${CGW_DATA}" ]]; then
    echo "${CGW_DATA}"
    pass "Azure Customer Gateways discovered"
else
    fail "Azure Customer Gateways not found"
fi

# ============================================================
# 15. VPN CONNECTIONS
# ============================================================

print_section "15. VPN CONNECTIONS"

VPN_DATA=$(aws ec2 describe-vpn-connections \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --vpn-connection-ids "${VPN_ID_01}" "${VPN_ID_02}" \
    --query 'VpnConnections[*].[VpnConnectionId,State,Type,TransitGatewayId,CustomerGatewayId,Category]' \
    --output table 2>/dev/null || true)

if [[ -n "${VPN_DATA}" ]]; then
    echo "${VPN_DATA}"
    pass "Azure VPN connections discovered"
else
    fail "Azure VPN connections not found"
fi

# ============================================================
# 16. VPN TUNNEL STATUS
# ============================================================

print_section "16. VPN TUNNEL STATUS"

for VPN_ID in "${VPN_ID_01}" "${VPN_ID_02}"; do

    echo
    echo "VPN Connection: ${VPN_ID}"
    echo "------------------------------------------------------------"

    TUNNEL_DATA=$(aws ec2 describe-vpn-connections \
        --profile "${AWS_PROFILE}" \
        --region "${AWS_REGION}" \
        --vpn-connection-ids "${VPN_ID}" \
        --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status,StatusMessage,AcceptedRouteCount,LastStatusChange]' \
        --output table 2>/dev/null || true)

    if [[ -n "${TUNNEL_DATA}" ]]; then
        echo "${TUNNEL_DATA}"
    else
        warn "Unable to retrieve tunnel telemetry for ${VPN_ID}"
    fi

done

# ============================================================
# 17. TGW AZURE ROUTES
# ============================================================

print_section "17. TGW ROUTES TO AZURE"

TGW_ROUTE_TABLE_IDS=$(aws ec2 describe-transit-gateway-route-tables \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filters "Name=transit-gateway-id,Values=${TGW_ID}" \
    --query 'TransitGatewayRouteTables[*].TransitGatewayRouteTableId' \
    --output text)

TGW_AZURE_ROUTE_FOUND=0

for TGW_RT_ID in ${TGW_ROUTE_TABLE_IDS}; do

    echo
    echo "TGW Route Table: ${TGW_RT_ID}"
    echo "------------------------------------------------------------"

    ROUTES=$(aws ec2 search-transit-gateway-routes \
        --profile "${AWS_PROFILE}" \
        --region "${AWS_REGION}" \
        --transit-gateway-route-table-id "${TGW_RT_ID}" \
        --filters "Name=type,Values=propagated,static" \
        --query 'Routes[?DestinationCidrBlock==`10.20.0.0/16`].[DestinationCidrBlock,Type,State,TransitGatewayAttachments[0].TransitGatewayAttachmentId]' \
        --output table 2>/dev/null || true)

    if [[ -n "${ROUTES}" ]]; then
        echo "${ROUTES}"
        TGW_AZURE_ROUTE_FOUND=1
    fi

done

if [[ "${TGW_AZURE_ROUTE_FOUND}" -eq 1 ]]; then
    pass "TGW route to Azure 10.20.0.0/16 exists"
else
    fail "TGW route to Azure 10.20.0.0/16 not found"
fi

# ============================================================
# 18. TGW NETWORK VPC ROUTE
# ============================================================

print_section "18. TGW NETWORK VPC ROUTE"

TGW_VPC_ROUTE_FOUND=0

for TGW_RT_ID in ${TGW_ROUTE_TABLE_IDS}; do

    ROUTES=$(aws ec2 search-transit-gateway-routes \
        --profile "${AWS_PROFILE}" \
        --region "${AWS_REGION}" \
        --transit-gateway-route-table-id "${TGW_RT_ID}" \
        --filters "Name=type,Values=propagated,static" \
        --query 'Routes[?DestinationCidrBlock==`10.0.0.0/20`].[DestinationCidrBlock,Type,State,TransitGatewayAttachments[0].TransitGatewayAttachmentId]' \
        --output table 2>/dev/null || true)

    if [[ -n "${ROUTES}" ]]; then
        echo
        echo "TGW Route Table: ${TGW_RT_ID}"
        echo "${ROUTES}"
        TGW_VPC_ROUTE_FOUND=1
    fi

done

if [[ "${TGW_VPC_ROUTE_FOUND}" -eq 1 ]]; then
    pass "TGW route to Network VPC 10.0.0.0/20 exists"
else
    fail "TGW route to Network VPC 10.0.0.0/20 not found"
fi

# ============================================================
# 19. AZURE VPN CUSTOMER GATEWAY DETAILS
# ============================================================

print_section "19. AZURE VPN / CUSTOMER GATEWAY DETAILS"

echo
echo "Customer Gateway 01:"
aws ec2 describe-customer-gateways \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --customer-gateway-ids "${CGW_ID_01}" \
    --query 'CustomerGateways[0].[CustomerGatewayId,State,Type,BgpAsn,IpAddress,Tags]' \
    --output table 2>/dev/null || true

echo
echo "Customer Gateway 02:"
aws ec2 describe-customer-gateways \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --customer-gateway-ids "${CGW_ID_02}" \
    --query 'CustomerGateways[0].[CustomerGatewayId,State,Type,BgpAsn,IpAddress,Tags]' \
    --output table 2>/dev/null || true

# ============================================================
# 20. VPN DETAILED CONFIGURATION
# ============================================================

print_section "20. VPN DETAILED CONFIGURATION"

for VPN_ID in "${VPN_ID_01}" "${VPN_ID_02}"; do

    echo
    echo "VPN: ${VPN_ID}"
    echo "------------------------------------------------------------"

    aws ec2 describe-vpn-connections \
        --profile "${AWS_PROFILE}" \
        --region "${AWS_REGION}" \
        --vpn-connection-ids "${VPN_ID}" \
        --query 'VpnConnections[0].[VpnConnectionId,State,Type,TransitGatewayId,CustomerGatewayId,Options.StaticRoutesOnly,Options.LocalIpv4NetworkCidr,Options.RemoteIpv4NetworkCidr]' \
        --output table 2>/dev/null || true

done

# ============================================================
# 21. NETWORK VPC ROUTES - FULL
# ============================================================

print_section "21. NETWORK VPC ROUTES"

for RT_ID in ${ROUTE_TABLE_IDS}; do

    echo
    echo "Route Table: ${RT_ID}"
    echo "------------------------------------------------------------"

    aws ec2 describe-route-tables \
        --profile "${AWS_PROFILE}" \
        --region "${AWS_REGION}" \
        --route-table-ids "${RT_ID}" \
        --query 'RouteTables[0].Routes[*].[DestinationCidrBlock,GatewayId,TransitGatewayId,NatGatewayId,State]' \
        --output table 2>/dev/null || true

done

# ============================================================
# 22. TAG INVENTORY
# ============================================================

print_section "22. VPC TAGS"

aws ec2 describe-vpcs \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --vpc-ids "${VPC_ID}" \
    --query 'Vpcs[0].Tags' \
    --output table 2>/dev/null || true

# ============================================================
# FINAL SUMMARY
# ============================================================

print_header "FINAL SUMMARY"

echo -e "${GREEN}PASS : ${PASS_COUNT}${NC}"
echo -e "${RED}FAIL : ${FAIL_COUNT}${NC}"
echo -e "${YELLOW}WARN : ${WARN_COUNT}${NC}"

echo
echo "AWS Profile : ${AWS_PROFILE}"
echo "AWS Region  : ${AWS_REGION}"
echo "AWS Account : ${ACCOUNT_ID}"
echo "VPC         : ${VPC_ID}"
echo "TGW         : ${TGW_ID}"

echo
echo "Expected Network Account:"
echo "360734036001"

echo
echo "Expected Azure Network:"
echo "Azure VNet       : 10.20.0.0/16"
echo "Azure Workload   : 10.20.1.0/24"
echo "Azure Gateway    : 10.20.255.0/24"

echo
echo "Expected AWS Network:"
echo "AWS Network VPC  : 10.0.0.0/20"

echo
echo "Expected Azure VPN BGP:"
echo "Azure ASN        : 65515"

echo
echo "Azure VPN CGWs:"
echo "CGW-01           : ${CGW_ID_01}"
echo "CGW-02           : ${CGW_ID_02}"

echo
echo "Azure VPNs:"
echo "VPN-01           : ${VPN_ID_01}"
echo "VPN-02           : ${VPN_ID_02}"

echo
echo "Expected Azure Route:"
echo "10.20.0.0/16 -> Transit Gateway"

echo
echo "============================================================"
echo "AWS NETWORK ACCOUNT CHECK COMPLETED"
echo "============================================================"
