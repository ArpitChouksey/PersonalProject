#!/bin/bash

set -uo pipefail

PROFILE="network"
REGION="us-east-1"
EXPECTED_ACCOUNT="360734036001"

echo "============================================================"
echo " AWS NETWORK ACCOUNT FULL CLEANUP"
echo "============================================================"
echo "Profile : ${PROFILE}"
echo "Region  : ${REGION}"
echo "Account : ${EXPECTED_ACCOUNT}"
echo "============================================================"

# ------------------------------------------------------------
# VALIDATE ACCOUNT
# ------------------------------------------------------------

ACCOUNT_ID=$(aws sts get-caller-identity \
  --profile "$PROFILE" \
  --query 'Account' \
  --output text 2>/dev/null)

if [ "$ACCOUNT_ID" != "$EXPECTED_ACCOUNT" ]; then
    echo "ERROR: Wrong AWS account!"
    echo "Expected: $EXPECTED_ACCOUNT"
    echo "Actual  : $ACCOUNT_ID"
    exit 1
fi

echo "Authentication: OK"
echo "Account: $ACCOUNT_ID"

echo
echo "============================================================"
echo "WARNING"
echo "============================================================"
echo
echo "This script will DELETE AWS RESOURCES from:"
echo
echo "  Account : $EXPECTED_ACCOUNT"
echo "  Region  : $REGION"
echo
echo "It is intended to completely remove the Enterprise"
echo "Master Networking project."
echo
echo "Terraform CODE will NOT be modified."
echo "AWS ACCOUNT will NOT be closed."
echo
echo "This includes:"
echo "  - Cloud WAN"
echo "  - Transit Gateway"
echo "  - TGW route tables"
echo "  - TGW attachments"
echo "  - RAM shares"
echo "  - VPN connections"
echo "  - Customer gateways"
echo "  - NAT gateways"
echo "  - Elastic IPs"
echo "  - VPCs"
echo "  - Subnets"
echo "  - Route tables"
echo "  - Internet gateways"
echo "  - VPC endpoints"
echo "  - IPAM"
echo
echo "============================================================"
read -r -p "Type DELETE-NETWORK to continue: " CONFIRM

if [ "$CONFIRM" != "DELETE-NETWORK" ]; then
    echo "Aborted."
    exit 1
fi

# ------------------------------------------------------------
# HELPER
# ------------------------------------------------------------

wait_for_delete() {
    local description="$1"
    local command="$2"

    echo "Waiting for ${description}..."

    for i in {1..30}; do
        if eval "$command" >/dev/null 2>&1; then
            sleep 10
        else
            echo "${description} appears to be deleted."
            return 0
        fi
    done

    echo "WARNING: Timeout waiting for ${description}"
}

# ============================================================
# 1. CLOUD WAN
# ============================================================

echo
echo "############################################################"
echo "# 1. CLOUD WAN"
echo "############################################################"

CORE_NETWORKS=$(aws networkmanager list-core-networks \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'CoreNetworks[].CoreNetworkId' \
    --output text 2>/dev/null)

for CORE in $CORE_NETWORKS; do

    echo
    echo "Core Network: $CORE"

    # --------------------------------------------------------
    # Delete Cloud WAN attachments
    # --------------------------------------------------------

    ATTACHMENTS=$(aws networkmanager list-attachments \
        --profile "$PROFILE" \
        --region "$REGION" \
        --core-network-id "$CORE" \
        --query 'AttachmentSummaries[].AttachmentId' \
        --output text 2>/dev/null)

    for ATT in $ATTACHMENTS; do
        echo "Deleting Cloud WAN attachment: $ATT"

        aws networkmanager delete-attachment \
            --profile "$PROFILE" \
            --region "$REGION" \
            --attachment-id "$ATT" || true
    done

    sleep 15

    # --------------------------------------------------------
    # Delete TGW peering attachments
    # --------------------------------------------------------

    TGW_PEERINGS=$(aws ec2 describe-transit-gateway-peering-attachments \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'TransitGatewayPeeringAttachments[].TransitGatewayAttachmentId' \
        --output text 2>/dev/null)

    for PEER in $TGW_PEERINGS; do
        echo "Deleting TGW peering attachment: $PEER"

        aws ec2 delete-transit-gateway-peering-attachment \
            --profile "$PROFILE" \
            --region "$REGION" \
            --transit-gateway-attachment-id "$PEER" || true
    done

    sleep 20

    echo "Deleting Cloud WAN core network: $CORE"

    aws networkmanager delete-core-network \
        --profile "$PROFILE" \
        --region "$REGION" \
        --core-network-id "$CORE" || true

done

sleep 30


# ============================================================
# 2. RAM SHARES
# ============================================================

echo
echo "############################################################"
echo "# 2. RAM RESOURCE SHARES"
echo "############################################################"

RAM_SHARES=$(aws ram get-resource-shares \
    --profile "$PROFILE" \
    --region "$REGION" \
    --resource-owner SELF \
    --query 'resourceShares[].resourceShareArn' \
    --output text 2>/dev/null)

for SHARE in $RAM_SHARES; do

    echo "Deleting RAM share: $SHARE"

    aws ram delete-resource-share \
        --profile "$PROFILE" \
        --region "$REGION" \
        --resource-share-arn "$SHARE" || true

done


# ============================================================
# 3. VPN CONNECTIONS
# ============================================================

echo
echo "############################################################"
echo "# 3. VPN CONNECTIONS"
echo "############################################################"

VPN_CONNECTIONS=$(aws ec2 describe-vpn-connections \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'VpnConnections[].VpnConnectionId' \
    --output text 2>/dev/null)

for VPN in $VPN_CONNECTIONS; do

    echo "Deleting VPN: $VPN"

    aws ec2 delete-vpn-connection \
        --profile "$PROFILE" \
        --region "$REGION" \
        --vpn-connection-id "$VPN" || true

done

sleep 20


# ============================================================
# 4. CUSTOMER GATEWAYS
# ============================================================

echo
echo "############################################################"
echo "# 4. CUSTOMER GATEWAYS"
echo "############################################################"

CGWS=$(aws ec2 describe-customer-gateways \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'CustomerGateways[].CustomerGatewayId' \
    --output text 2>/dev/null)

for CGW in $CGWS; do

    echo "Deleting Customer Gateway: $CGW"

    aws ec2 delete-customer-gateway \
        --profile "$PROFILE" \
        --region "$REGION" \
        --customer-gateway-id "$CGW" || true

done


# ============================================================
# 5. TGW VPC ATTACHMENTS
# ============================================================

echo
echo "############################################################"
echo "# 5. TRANSIT GATEWAY VPC ATTACHMENTS"
echo "############################################################"

TGW_ATTACHMENTS=$(aws ec2 describe-transit-gateway-attachments \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'TransitGatewayAttachments[?ResourceType==`vpc`].TransitGatewayAttachmentId' \
    --output text 2>/dev/null)

for ATT in $TGW_ATTACHMENTS; do

    echo "Deleting TGW VPC attachment: $ATT"

    aws ec2 delete-transit-gateway-vpc-attachment \
        --profile "$PROFILE" \
        --region "$REGION" \
        --transit-gateway-attachment-id "$ATT" || true

done

sleep 30


# ============================================================
# 6. TGW ROUTE TABLE ASSOCIATIONS
# ============================================================

echo
echo "############################################################"
echo "# 6. TGW ROUTE TABLE ASSOCIATIONS"
echo "############################################################"

TGW_RTS=$(aws ec2 describe-transit-gateway-route-tables \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'TransitGatewayRouteTables[].TransitGatewayRouteTableId' \
    --output text 2>/dev/null)

for RT in $TGW_RTS; do

    echo
    echo "Processing TGW route table: $RT"

    ASSOCIATIONS=$(aws ec2 get-transit-gateway-route-table-associations \
        --profile "$PROFILE" \
        --region "$REGION" \
        --transit-gateway-route-table-id "$RT" \
        --query 'Associations[].TransitGatewayAttachmentId' \
        --output text 2>/dev/null)

    for ATT in $ASSOCIATIONS; do

        echo "Disassociating $ATT from $RT"

        aws ec2 disassociate-transit-gateway-route-table \
            --profile "$PROFILE" \
            --region "$REGION" \
            --transit-gateway-route-table-id "$RT" \
            --transit-gateway-attachment-id "$ATT" || true

    done

done

sleep 20


# ============================================================
# 7. TGW ROUTE TABLE PROPAGATIONS
# ============================================================

echo
echo "############################################################"
echo "# 7. TGW ROUTE TABLE PROPAGATIONS"
echo "############################################################"

for RT in $TGW_RTS; do

    PROPAGATIONS=$(aws ec2 get-transit-gateway-route-table-propagations \
        --profile "$PROFILE" \
        --region "$REGION" \
        --transit-gateway-route-table-id "$RT" \
        --query 'TransitGatewayRouteTablePropagations[].TransitGatewayAttachmentId' \
        --output text 2>/dev/null)

    for ATT in $PROPAGATIONS; do

        echo "Disabling propagation $ATT -> $RT"

        aws ec2 disable-transit-gateway-route-table-propagation \
            --profile "$PROFILE" \
            --region "$REGION" \
            --transit-gateway-route-table-id "$RT" \
            --transit-gateway-attachment-id "$ATT" || true

    done

done

sleep 20


# ============================================================
# 8. TGW ROUTES
# ============================================================

echo
echo "############################################################"
echo "# 8. TGW ROUTES"
echo "############################################################"

for RT in $TGW_RTS; do

    echo "Checking routes in: $RT"

    ROUTES=$(aws ec2 search-transit-gateway-routes \
        --profile "$PROFILE" \
        --region "$REGION" \
        --transit-gateway-route-table-id "$RT" \
        --filters "state=active" \
        --query 'Routes[].DestinationCidrBlock' \
        --output text 2>/dev/null)

    for CIDR in $ROUTES; do

        echo "Deleting TGW route: $CIDR from $RT"

        aws ec2 delete-transit-gateway-route \
            --profile "$PROFILE" \
            --region "$REGION" \
            --transit-gateway-route-table-id "$RT" \
            --destination-cidr-block "$CIDR" || true

    done

done


# ============================================================
# 9. TGW ROUTE TABLE ANNOUNCEMENTS
# ============================================================

echo
echo "############################################################"
echo "# 9. TGW ROUTE TABLE ANNOUNCEMENTS"
echo "############################################################"

for RT in $TGW_RTS; do

    ANNOUNCEMENTS=$(aws ec2 get-transit-gateway-route-table-announcements \
        --profile "$PROFILE" \
        --region "$REGION" \
        --transit-gateway-route-table-id "$RT" \
        --query 'TransitGatewayRouteTableAnnouncements[].TransitGatewayRouteTableAnnouncementId' \
        --output text 2>/dev/null)

    for ANN in $ANNOUNCEMENTS; do

        echo "Deleting route table announcement: $ANN"

        aws ec2 delete-transit-gateway-route-table-announcement \
            --profile "$PROFILE" \
            --region "$REGION" \
            --transit-gateway-route-table-announcement-id "$ANN" || true

    done

done


# ============================================================
# 10. DELETE TGW ROUTE TABLES
# ============================================================

echo
echo "############################################################"
echo "# 10. DELETE TGW ROUTE TABLES"
echo "############################################################"

for RT in $TGW_RTS; do

    echo "Deleting TGW route table: $RT"

    aws ec2 delete-transit-gateway-route-table \
        --profile "$PROFILE" \
        --region "$REGION" \
        --transit-gateway-route-table-id "$RT" || true

done

sleep 20


# ============================================================
# 11. DELETE TRANSIT GATEWAYS
# ============================================================

echo
echo "############################################################"
echo "# 11. DELETE TRANSIT GATEWAYS"
echo "############################################################"

TGWS=$(aws ec2 describe-transit-gateways \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'TransitGateways[?State!=`deleted`].TransitGatewayId' \
    --output text 2>/dev/null)

for TGW in $TGWS; do

    echo "Deleting Transit Gateway: $TGW"

    aws ec2 delete-transit-gateway \
        --profile "$PROFILE" \
        --region "$REGION" \
        --transit-gateway-id "$TGW" || true

done

sleep 40


# ============================================================
# 12. VPC ENDPOINTS
# ============================================================

echo
echo "############################################################"
echo "# 12. VPC ENDPOINTS"
echo "############################################################"

VPCE=$(aws ec2 describe-vpc-endpoints \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'VpcEndpoints[].VpcEndpointId' \
    --output text 2>/dev/null)

if [ -n "$VPCE" ]; then

    echo "Deleting VPC endpoints"

    aws ec2 delete-vpc-endpoints \
        --profile "$PROFILE" \
        --region "$REGION" \
        --vpc-endpoint-ids $VPCE || true

fi


# ============================================================
# 13. NAT GATEWAYS
# ============================================================

echo
echo "############################################################"
echo "# 13. NAT GATEWAYS"
echo "############################################################"

NATS=$(aws ec2 describe-nat-gateways \
    --profile "$PROFILE" \
    --region "$REGION" \
    --filter Name=state,Values=available,pending \
    --query 'NatGateways[].NatGatewayId' \
    --output text 2>/dev/null)

for NAT in $NATS; do

    echo "Deleting NAT Gateway: $NAT"

    aws ec2 delete-nat-gateway \
        --profile "$PROFILE" \
        --region "$REGION" \
        --nat-gateway-id "$NAT" || true

done

sleep 30


# ============================================================
# 14. NETWORK INTERFACES
# ============================================================

echo
echo "############################################################"
echo "# 14. NETWORK INTERFACES"
echo "############################################################"

ENIS=$(aws ec2 describe-network-interfaces \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'NetworkInterfaces[].NetworkInterfaceId' \
    --output text 2>/dev/null)

for ENI in $ENIS; do

    DESCRIPTION=$(aws ec2 describe-network-interfaces \
        --profile "$PROFILE" \
        --region "$REGION" \
        --network-interface-ids "$ENI" \
        --query 'NetworkInterfaces[0].Description' \
        --output text 2>/dev/null)

    echo "ENI: $ENI"
    echo "Description: $DESCRIPTION"

    aws ec2 delete-network-interface \
        --profile "$PROFILE" \
        --region "$REGION" \
        --network-interface-id "$ENI" 2>/dev/null || true

done


# ============================================================
# 15. ELASTIC IPS
# ============================================================

echo
echo "############################################################"
echo "# 15. ELASTIC IPS"
echo "############################################################"

EIPS=$(aws ec2 describe-addresses \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Addresses[].AllocationId' \
    --output text 2>/dev/null)

for EIP in $EIPS; do

    echo "Releasing EIP: $EIP"

    aws ec2 release-address \
        --profile "$PROFILE" \
        --region "$REGION" \
        --allocation-id "$EIP" || true

done


# ============================================================
# 16. ROUTE TABLES
# ============================================================

echo
echo "############################################################"
echo "# 16. ROUTE TABLES"
echo "############################################################"

VPCS=$(aws ec2 describe-vpcs \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Vpcs[].VpcId' \
    --output text 2>/dev/null)

for VPC in $VPCS; do

    ROUTE_TABLES=$(aws ec2 describe-route-tables \
        --profile "$PROFILE" \
        --region "$REGION" \
        --filters Name=vpc-id,Values="$VPC" \
        --query 'RouteTables[].RouteTableId' \
        --output text 2>/dev/null)

    for RT in $ROUTE_TABLES; do

        MAIN=$(aws ec2 describe-route-tables \
            --profile "$PROFILE" \
            --region "$REGION" \
            --route-table-ids "$RT" \
            --query 'RouteTables[0].Associations[?Main==`true`].Main' \
            --output text 2>/dev/null)

        if [ "$MAIN" = "True" ]; then
            echo "Skipping MAIN route table: $RT"
        else
            echo "Deleting route table: $RT"

            aws ec2 delete-route-table \
                --profile "$PROFILE" \
                --region "$REGION" \
                --route-table-id "$RT" || true
        fi

    done

done


# ============================================================
# 17. SUBNETS
# ============================================================

echo
echo "############################################################"
echo "# 17. SUBNETS"
echo "############################################################"

SUBNETS=$(aws ec2 describe-subnets \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Subnets[].SubnetId' \
    --output text 2>/dev/null)

for SUBNET in $SUBNETS; do

    echo "Deleting subnet: $SUBNET"

    aws ec2 delete-subnet \
        --profile "$PROFILE" \
        --region "$REGION" \
        --subnet-id "$SUBNET" || true

done


# ============================================================
# 18. INTERNET GATEWAYS
# ============================================================

echo
echo "############################################################"
echo "# 18. INTERNET GATEWAYS"
echo "############################################################"

IGWS=$(aws ec2 describe-internet-gateways \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'InternetGateways[].{Id:InternetGatewayId,Vpc:Attachments[0].VpcId}' \
    --output text 2>/dev/null)

while read -r IGW VPC; do

    [ -z "$IGW" ] && continue

    echo "Processing IGW: $IGW"

    if [ "$VPC" != "None" ] && [ -n "$VPC" ]; then

        echo "Detaching $IGW from $VPC"

        aws ec2 detach-internet-gateway \
            --profile "$PROFILE" \
            --region "$REGION" \
            --internet-gateway-id "$IGW" \
            --vpc-id "$VPC" || true

    fi

    echo "Deleting IGW: $IGW"

    aws ec2 delete-internet-gateway \
        --profile "$PROFILE" \
        --region "$REGION" \
        --internet-gateway-id "$IGW" || true

done <<< "$IGWS"


# ============================================================
# 19. DELETE VPCS
# ============================================================

echo
echo "############################################################"
echo "# 19. DELETE VPCS"
echo "############################################################"

VPCS=$(aws ec2 describe-vpcs \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Vpcs[].VpcId' \
    --output text 2>/dev/null)

for VPC in $VPCS; do

    echo "Deleting VPC: $VPC"

    aws ec2 delete-vpc \
        --profile "$PROFILE" \
        --region "$REGION" \
        --vpc-id "$VPC" || true

done


# ============================================================
# 20. IPAM POOLS
# ============================================================

echo
echo "############################################################"
echo "# 20. VPC IPAM"
echo "############################################################"

IPAMS=$(aws ec2 describe-ipams \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Ipams[].IpamId' \
    --output text 2>/dev/null)

for IPAM in $IPAMS; do

    echo
    echo "IPAM: $IPAM"

    POOLS=$(aws ec2 describe-ipam-pools \
        --profile "$PROFILE" \
        --region "$REGION" \
        --filters Name=ipam-id,Values="$IPAM" \
        --query 'IpamPools[].IpamPoolId' \
        --output text 2>/dev/null)

    for POOL in $POOLS; do

        echo "Releasing CIDRs from pool: $POOL"

        CIDRS=$(aws ec2 get-ipam-pool-cidrs \
            --profile "$PROFILE" \
            --region "$REGION" \
            --ipam-pool-id "$POOL" \
            --query 'IpamPoolCidrs[].IpamPoolCidrId' \
            --output text 2>/dev/null)

        for CIDR_ID in $CIDRS; do

            echo "Deleting IPAM pool CIDR: $CIDR_ID"

            aws ec2 deprovision-ipam-pool-cidr \
                --profile "$PROFILE" \
                --region "$REGION" \
                --ipam-pool-id "$POOL" \
                --ipam-pool-cidr-id "$CIDR_ID" || true

        done

    done

done

sleep 20


# ============================================================
# 21. DELETE IPAM POOLS - CHILDREN FIRST
# ============================================================

echo
echo "############################################################"
echo "# 21. DELETE IPAM POOLS"
echo "############################################################"

for IPAM in $IPAMS; do

    POOLS=$(aws ec2 describe-ipam-pools \
        --profile "$PROFILE" \
        --region "$REGION" \
        --filters Name=ipam-id,Values="$IPAM" \
        --query 'IpamPools[].IpamPoolId' \
        --output text 2>/dev/null)

    for POOL in $POOLS; do

        echo "Deleting IPAM pool: $POOL"

        aws ec2 delete-ipam-pool \
            --profile "$PROFILE" \
            --region "$REGION" \
            --ipam-pool-id "$POOL" || true

    done

done

sleep 20


# ============================================================
# 22. DELETE IPAM
# ============================================================

echo
echo "############################################################"
echo "# 22. DELETE IPAM"
echo "############################################################"

for IPAM in $IPAMS; do

    echo "Deleting IPAM: $IPAM"

    aws ec2 delete-ipam \
        --profile "$PROFILE" \
        --region "$REGION" \
        --ipam-id "$IPAM" \
        --cascade || true

done


# ============================================================
# 23. FINAL NETWORK SCAN
# ============================================================

echo
echo "============================================================"
echo " FINAL NETWORK ACCOUNT SCAN"
echo "============================================================"

echo
echo "VPCs:"
aws ec2 describe-vpcs \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,Default:IsDefault}' \
    --output table

echo
echo "NAT Gateways:"
aws ec2 describe-nat-gateways \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'NatGateways[].{Id:NatGatewayId,State:State}' \
    --output table

echo
echo "Elastic IPs:"
aws ec2 describe-addresses \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Addresses[].{AllocationId:AllocationId,PublicIp:PublicIp}' \
    --output table

echo
echo "Transit Gateways:"
aws ec2 describe-transit-gateways \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'TransitGateways[].{Id:TransitGatewayId,State:State}' \
    --output table

echo
echo "TGW Attachments:"
aws ec2 describe-transit-gateway-attachments \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'TransitGatewayAttachments[].{Id:TransitGatewayAttachmentId,State:State,Type:ResourceType}' \
    --output table

echo
echo "VPN:"
aws ec2 describe-vpn-connections \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'VpnConnections[].{Id:VpnConnectionId,State:State}' \
    --output table

echo
echo "Customer Gateways:"
aws ec2 describe-customer-gateways \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'CustomerGateways[].{Id:CustomerGatewayId,State:State}' \
    --output table

echo
echo "IPAM:"
aws ec2 describe-ipams \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Ipams[].{Id:IpamId,State:State}' \
    --output table

echo
echo "Cloud WAN:"
aws networkmanager list-core-networks \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'CoreNetworks[].{Id:CoreNetworkId,State:State}' \
    --output table

echo
echo "RAM Shares:"
aws ram get-resource-shares \
    --profile "$PROFILE" \
    --region "$REGION" \
    --resource-owner SELF \
    --query 'resourceShares[].{Name:name,Status:status}' \
    --output table

echo
echo "============================================================"
echo " NETWORK CLEANUP PASS COMPLETE"
echo "============================================================"
echo
echo "Terraform code was NOT modified."
echo "AWS account was NOT closed."
echo
echo "Review the FINAL SCAN carefully."
echo "============================================================"
