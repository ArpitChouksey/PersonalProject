#!/bin/bash

set -u

REGION="us-east-1"

PROD_PROFILE="production"
PROD_ACCOUNT="025775692925"

SHARED_PROFILE="sharedservice"
SHARED_ACCOUNT="070977799818"

echo "============================================================"
echo " AWS PROJECT CLEANUP"
echo " Region: $REGION"
echo "============================================================"
echo

# ------------------------------------------------------------
# Utility
# ------------------------------------------------------------

run() {
    "$@" 2>&1 || true
}

wait_for() {
    local seconds="$1"
    echo "Waiting ${seconds}s..."
    sleep "$seconds"
}

confirm_account() {
    local PROFILE="$1"
    local EXPECTED="$2"
    local NAME="$3"

    echo
    echo "------------------------------------------------------------"
    echo "Validating $NAME"
    echo "Profile : $PROFILE"
    echo "Expected: $EXPECTED"
    echo "------------------------------------------------------------"

    ID=$(aws sts get-caller-identity \
        --profile "$PROFILE" \
        --query Account \
        --output text 2>/dev/null || true)

    if [ -z "$ID" ] || [ "$ID" = "None" ]; then
        echo "ERROR: Cannot authenticate using profile $PROFILE"
        return 1
    fi

    echo "Actual account: $ID"

    if [ "$ID" != "$EXPECTED" ]; then
        echo "ERROR: Account mismatch!"
        echo "Expected: $EXPECTED"
        echo "Actual:   $ID"
        return 1
    fi

    echo "Authentication: OK"
    return 0
}

# ------------------------------------------------------------
# Validate both accounts BEFORE deleting anything
# ------------------------------------------------------------

confirm_account "$PROD_PROFILE" "$PROD_ACCOUNT" "PRODUCTION"
PROD_OK=$?

confirm_account "$SHARED_PROFILE" "$SHARED_ACCOUNT" "SHARED SERVICES"
SHARED_OK=$?

if [ "$PROD_OK" -ne 0 ] || [ "$SHARED_OK" -ne 0 ]; then
    echo
    echo "============================================================"
    echo "ABORTED"
    echo "One or more account validations failed."
    echo "============================================================"
    exit 1
fi

echo
echo "============================================================"
echo "Both account validations passed."
echo "============================================================"

# ------------------------------------------------------------
# Safety confirmation
# ------------------------------------------------------------

echo
echo "THIS WILL DELETE PROJECT RESOURCES IN:"
echo
echo "Production:"
echo "  Account: $PROD_ACCOUNT"
echo
echo "Shared Services:"
echo "  Account: $SHARED_ACCOUNT"
echo
echo "Region:"
echo "  $REGION"
echo
echo "Terraform code will NOT be modified."
echo "AWS accounts will NOT be closed."
echo

read -r -p "Type DELETE to continue: " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# ============================================================
# FUNCTION: CLEAN ACCOUNT
# ============================================================

clean_account() {

    PROFILE="$1"
    ACCOUNT="$2"
    NAME="$3"

    echo
    echo "############################################################"
    echo "# CLEANING $NAME"
    echo "# ACCOUNT: $ACCOUNT"
    echo "############################################################"

    # --------------------------------------------------------
    # Revalidate account
    # --------------------------------------------------------

    CURRENT=$(aws sts get-caller-identity \
        --profile "$PROFILE" \
        --query Account \
        --output text)

    if [ "$CURRENT" != "$ACCOUNT" ]; then
        echo "ERROR: Wrong account detected."
        exit 1
    fi

    # --------------------------------------------------------
    # EC2 INSTANCES
    # --------------------------------------------------------

    echo
    echo ">>> EC2 instances"

    INSTANCE_IDS=$(aws ec2 describe-instances \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' \
        --output text)

    if [ -n "$INSTANCE_IDS" ]; then
        echo "Stopping instances:"
        echo "$INSTANCE_IDS"

        aws ec2 stop-instances \
            --profile "$PROFILE" \
            --region "$REGION" \
            --instance-ids $INSTANCE_IDS || true

        aws ec2 wait instance-stopped \
            --profile "$PROFILE" \
            --region "$REGION" \
            --instance-ids $INSTANCE_IDS || true

        echo "Terminating instances..."

        aws ec2 terminate-instances \
            --profile "$PROFILE" \
            --region "$REGION" \
            --instance-ids $INSTANCE_IDS || true

        aws ec2 wait instance-terminated \
            --profile "$PROFILE" \
            --region "$REGION" \
            --instance-ids $INSTANCE_IDS || true
    else
        echo "No running EC2 instances."
    fi

    # --------------------------------------------------------
    # LOAD BALANCERS
    # --------------------------------------------------------

    echo
    echo ">>> Application Load Balancers / Network Load Balancers"

    LB_ARNS=$(aws elbv2 describe-load-balancers \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'LoadBalancers[].LoadBalancerArn' \
        --output text)

    if [ -n "$LB_ARNS" ]; then
        for ARN in $LB_ARNS; do
            echo "Deleting LB: $ARN"

            aws elbv2 delete-load-balancer \
                --profile "$PROFILE" \
                --region "$REGION" \
                --load-balancer-arn "$ARN" || true
        done
    else
        echo "No ALB/NLB found."
    fi

    wait_for 20

    # --------------------------------------------------------
    # TARGET GROUPS
    # --------------------------------------------------------

    echo
    echo ">>> Target Groups"

    TG_ARNS=$(aws elbv2 describe-target-groups \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'TargetGroups[].TargetGroupArn' \
        --output text)

    if [ -n "$TG_ARNS" ]; then
        for ARN in $TG_ARNS; do
            echo "Deleting target group: $ARN"

            aws elbv2 delete-target-group \
                --profile "$PROFILE" \
                --region "$REGION" \
                --target-group-arn "$ARN" || true
        done
    fi

    # --------------------------------------------------------
    # VPC ENDPOINTS
    # --------------------------------------------------------

    echo
    echo ">>> VPC Endpoints"

    ENDPOINT_IDS=$(aws ec2 describe-vpc-endpoints \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'VpcEndpoints[].VpcEndpointId' \
        --output text)

    if [ -n "$ENDPOINT_IDS" ]; then
        aws ec2 delete-vpc-endpoints \
            --profile "$PROFILE" \
            --region "$REGION" \
            --vpc-endpoint-ids $ENDPOINT_IDS || true
    fi

    # --------------------------------------------------------
    # NAT GATEWAYS
    # --------------------------------------------------------

    echo
    echo ">>> NAT Gateways"

    NAT_IDS=$(aws ec2 describe-nat-gateways \
        --profile "$PROFILE" \
        --region "$REGION" \
        --filter Name=state,Values=available,pending,deleting \
        --query 'NatGateways[].NatGatewayId' \
        --output text)

    if [ -n "$NAT_IDS" ]; then

        for NAT in $NAT_IDS; do

            echo "Deleting NAT Gateway: $NAT"

            aws ec2 delete-nat-gateway \
                --profile "$PROFILE" \
                --region "$REGION" \
                --nat-gateway-id "$NAT" || true

        done

        echo "Waiting for NAT gateways to disappear..."

        for NAT in $NAT_IDS; do

            for i in {1..30}; do

                STATE=$(aws ec2 describe-nat-gateways \
                    --profile "$PROFILE" \
                    --region "$REGION" \
                    --nat-gateway-ids "$NAT" \
                    --query 'NatGateways[0].State' \
                    --output text 2>/dev/null || echo "deleted")

                echo "$NAT -> $STATE"

                if [ "$STATE" = "deleted" ] || [ "$STATE" = "None" ]; then
                    break
                fi

                sleep 10
            done

        done
    else
        echo "No NAT Gateways."
    fi

    # --------------------------------------------------------
    # VPN CONNECTIONS
    # --------------------------------------------------------

    echo
    echo ">>> VPN Connections"

    VPN_IDS=$(aws ec2 describe-vpn-connections \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'VpnConnections[].VpnConnectionId' \
        --output text)

    if [ -n "$VPN_IDS" ]; then

        for VPN in $VPN_IDS; do
            echo "Deleting VPN: $VPN"

            aws ec2 delete-vpn-connection \
                --profile "$PROFILE" \
                --region "$REGION" \
                --vpn-connection-id "$VPN" || true
        done

    fi

    # --------------------------------------------------------
    # TGW VPC ATTACHMENTS
    # --------------------------------------------------------

    echo
    echo ">>> Transit Gateway VPC Attachments"

    TGW_ATTACHMENTS=$(aws ec2 describe-transit-gateway-vpc-attachments \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'TransitGatewayVpcAttachments[?State!=`deleted`].TransitGatewayAttachmentId' \
        --output text)

    if [ -n "$TGW_ATTACHMENTS" ]; then

        for ATTACHMENT in $TGW_ATTACHMENTS; do

            echo "Deleting TGW attachment: $ATTACHMENT"

            aws ec2 delete-transit-gateway-vpc-attachment \
                --profile "$PROFILE" \
                --region "$REGION" \
                --transit-gateway-attachment-id "$ATTACHMENT" || true

        done

        wait_for 30
    else
        echo "No TGW VPC attachments."
    fi

    # --------------------------------------------------------
    # NETWORK INTERFACES
    # --------------------------------------------------------

    echo
    echo ">>> Network Interfaces"

    ENI_IDS=$(aws ec2 describe-network-interfaces \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'NetworkInterfaces[].NetworkInterfaceId' \
        --output text)

    if [ -n "$ENI_IDS" ]; then

        for ENI in $ENI_IDS; do

            DESCRIPTION=$(aws ec2 describe-network-interfaces \
                --profile "$PROFILE" \
                --region "$REGION" \
                --network-interface-ids "$ENI" \
                --query 'NetworkInterfaces[0].Description' \
                --output text 2>/dev/null || true)

            echo "$ENI -> $DESCRIPTION"

            aws ec2 delete-network-interface \
                --profile "$PROFILE" \
                --region "$REGION" \
                --network-interface-id "$ENI" || true

        done

    else
        echo "No ENIs."
    fi

    # --------------------------------------------------------
    # RELEASE ELASTIC IPS
    # --------------------------------------------------------

    echo
    echo ">>> Elastic IPs"

    EIP_DATA=$(aws ec2 describe-addresses \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Addresses[].[AllocationId,AssociationId,PublicIp]' \
        --output text)

    if [ -n "$EIP_DATA" ]; then

        while read -r ALLOCATION ASSOCIATION PUBLICIP; do

            [ -z "$ALLOCATION" ] && continue

            echo "EIP: $PUBLICIP"

            if [ "$ASSOCIATION" != "None" ] && [ -n "$ASSOCIATION" ]; then

                echo "Disassociating: $ASSOCIATION"

                aws ec2 disassociate-address \
                    --profile "$PROFILE" \
                    --region "$REGION" \
                    --association-id "$ASSOCIATION" || true

            fi

            echo "Releasing: $ALLOCATION"

            aws ec2 release-address \
                --profile "$PROFILE" \
                --region "$REGION" \
                --allocation-id "$ALLOCATION" || true

        done <<< "$EIP_DATA"

    else
        echo "No Elastic IPs."
    fi

    # --------------------------------------------------------
    # ROUTE TABLES
    # --------------------------------------------------------

    echo
    echo ">>> Route Tables"

    ROUTE_TABLES=$(aws ec2 describe-route-tables \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'RouteTables[].RouteTableId' \
        --output text)

    if [ -n "$ROUTE_TABLES" ]; then

        for RTB in $ROUTE_TABLES; do

            # Never delete the AWS main/default route table blindly.
            MAIN=$(aws ec2 describe-route-tables \
                --profile "$PROFILE" \
                --region "$REGION" \
                --route-table-ids "$RTB" \
                --query 'RouteTables[0].Associations[?Main==`true`].Main' \
                --output text 2>/dev/null || true)

            if [ "$MAIN" = "True" ]; then
                echo "Skipping MAIN route table: $RTB"
                continue
            fi

            ASSOCIATIONS=$(aws ec2 describe-route-tables \
                --profile "$PROFILE" \
                --region "$REGION" \
                --route-table-ids "$RTB" \
                --query 'RouteTables[0].Associations[?Main!=`true`].RouteTableAssociationId' \
                --output text)

            for ASSOC in $ASSOCIATIONS; do

                echo "Deleting route association: $ASSOC"

                aws ec2 disassociate-route-table \
                    --profile "$PROFILE" \
                    --region "$REGION" \
                    --association-id "$ASSOC" || true

            done

            echo "Deleting route table: $RTB"

            aws ec2 delete-route-table \
                --profile "$PROFILE" \
                --region "$REGION" \
                --route-table-id "$RTB" || true

        done

    fi

    # --------------------------------------------------------
    # SUBNETS
    # --------------------------------------------------------

    echo
    echo ">>> Subnets"

    SUBNETS=$(aws ec2 describe-subnets \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Subnets[].SubnetId' \
        --output text)

    if [ -n "$SUBNETS" ]; then

        for SUBNET in $SUBNETS; do

            echo "Deleting subnet: $SUBNET"

            aws ec2 delete-subnet \
                --profile "$PROFILE" \
                --region "$REGION" \
                --subnet-id "$SUBNET" || true

        done

    fi

    # --------------------------------------------------------
    # INTERNET GATEWAYS
    # --------------------------------------------------------

    echo
    echo ">>> Internet Gateways"

    IGWS=$(aws ec2 describe-internet-gateways \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'InternetGateways[].InternetGatewayId' \
        --output text)

    if [ -n "$IGWS" ]; then

        for IGW in $IGWS; do

            VPC_ID=$(aws ec2 describe-internet-gateways \
                --profile "$PROFILE" \
                --region "$REGION" \
                --internet-gateway-ids "$IGW" \
                --query 'InternetGateways[0].Attachments[0].VpcId' \
                --output text 2>/dev/null || true)

            if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then

                echo "Detaching $IGW from $VPC_ID"

                aws ec2 detach-internet-gateway \
                    --profile "$PROFILE" \
                    --region "$REGION" \
                    --internet-gateway-id "$IGW" \
                    --vpc-id "$VPC_ID" || true

            fi

            echo "Deleting IGW: $IGW"

            aws ec2 delete-internet-gateway \
                --profile "$PROFILE" \
                --region "$REGION" \
                --internet-gateway-id "$IGW" || true

        done

    fi

    # --------------------------------------------------------
    # NON-DEFAULT VPCS ONLY
    # --------------------------------------------------------

    echo
    echo ">>> Non-default VPCs"

    VPCS=$(aws ec2 describe-vpcs \
        --profile "$PROFILE" \
        --region "$REGION" \
        --filters Name=is-default,Values=false \
        --query 'Vpcs[].VpcId' \
        --output text)

    if [ -n "$VPCS" ]; then

        for VPC in $VPCS; do

            echo "Deleting VPC: $VPC"

            aws ec2 delete-vpc \
                --profile "$PROFILE" \
                --region "$REGION" \
                --vpc-id "$VPC" || true

        done

    else
        echo "No non-default VPCs."
    fi

    # --------------------------------------------------------
    # FINAL ACCOUNT SCAN
    # --------------------------------------------------------

    echo
    echo "============================================================"
    echo "FINAL SCAN: $NAME"
    echo "============================================================"

    echo
    echo "VPCs:"
    aws ec2 describe-vpcs \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Vpcs[].[VpcId,CidrBlock,IsDefault]' \
        --output table

    echo
    echo "NAT Gateways:"
    aws ec2 describe-nat-gateways \
        --profile "$PROFILE" \
        --region "$REGION" \
        --filter Name=state,Values=available,pending \
        --query 'NatGateways[].[NatGatewayId,State,VpcId]' \
        --output table

    echo
    echo "Elastic IPs:"
    aws ec2 describe-addresses \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Addresses[].[PublicIp,AllocationId,AssociationId]' \
        --output table

    echo
    echo "TGW Attachments:"
    aws ec2 describe-transit-gateway-vpc-attachments \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'TransitGatewayVpcAttachments[].[TransitGatewayAttachmentId,State,VpcId]' \
        --output table 2>/dev/null || true

    echo
    echo "EC2:"
    aws ec2 describe-instances \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Reservations[].Instances[?State.Name!=`terminated`].[InstanceId,State.Name]' \
        --output table

    echo
    echo "============================================================"
    echo "$NAME CLEANUP PASS COMPLETE"
    echo "============================================================"
}

# ============================================================
# EXECUTION
# ============================================================

clean_account \
    "$PROD_PROFILE" \
    "$PROD_ACCOUNT" \
    "PRODUCTION"

clean_account \
    "$SHARED_PROFILE" \
    "$SHARED_ACCOUNT" \
    "SHARED SERVICES"

echo
echo "============================================================"
echo " BOTH ACCOUNT CLEANUP PASSES COMPLETED"
echo "============================================================"
echo
echo "IMPORTANT:"
echo "Accounts were NOT closed."
echo "Terraform code was NOT modified."
echo
echo "Review the FINAL SCAN output above."
echo "============================================================"
