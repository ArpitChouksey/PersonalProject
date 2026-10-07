#!/bin/bash

set -euo pipefail

REGION="us-east-1"
OUTPUT_DIR="inventory"

mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo " AWS ORGANIZATION / CONTROL TOWER / IAM VALIDATION"
echo "============================================================"
echo

# ------------------------------------------------------------
# 1. Validate AWS CLI identity
# ------------------------------------------------------------

echo "[1/12] Validating AWS identity..."

aws sts get-caller-identity \
  --output json | tee "$OUTPUT_DIR/identity.json"

ACCOUNT_ID=$(aws sts get-caller-identity \
  --query 'Account' \
  --output text)

CALLER_ARN=$(aws sts get-caller-identity \
  --query 'Arn' \
  --output text)

echo
echo "Account : $ACCOUNT_ID"
echo "Identity: $CALLER_ARN"
echo

if [[ "$ACCOUNT_ID" != "211811255273" ]]; then
    echo "ERROR: This is not the Management Account."
    echo "Expected: 211811255273"
    exit 1
fi

echo "Management account validation: PASSED"
echo


# ------------------------------------------------------------
# 2. AWS Organization
# ------------------------------------------------------------

echo "[2/12] Getting AWS Organization..."

aws organizations describe-organization \
  --output json | tee "$OUTPUT_DIR/organization.json"

ORG_ID=$(aws organizations describe-organization \
  --query 'Organization.Id' \
  --output text)

ROOT_ID=$(aws organizations list-roots \
  --query 'Roots[0].Id' \
  --output text)

echo
echo "Organization ID: $ORG_ID"
echo "Root ID        : $ROOT_ID"
echo


# ------------------------------------------------------------
# 3. Root
# ------------------------------------------------------------

echo "[3/12] Getting Organization Root..."

aws organizations list-roots \
  --output json | tee "$OUTPUT_DIR/roots.json"

echo


# ------------------------------------------------------------
# 4. Organizational Units
# ------------------------------------------------------------

echo "[4/12] Getting Organizational Units..."

aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" \
  --output json | tee "$OUTPUT_DIR/ous.json"

echo
echo "OUs:"
aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" \
  --query 'OrganizationalUnits[].{Name:Name,Id:Id,Arn:Arn}' \
  --output table

echo


# ------------------------------------------------------------
# 5. Accounts
# ------------------------------------------------------------

echo "[5/12] Getting Organization Accounts..."

aws organizations list-accounts \
  --output json | tee "$OUTPUT_DIR/accounts.json"

echo
echo "Accounts:"
aws organizations list-accounts \
  --query 'Accounts[].{Name:Name,Id:Id,Status:Status,Email:Email,Arn:Arn}' \
  --output table

echo


# ------------------------------------------------------------
# 6. SCPs
# ------------------------------------------------------------

echo "[6/12] Getting Service Control Policies..."

aws organizations list-policies \
  --filter SERVICE_CONTROL_POLICY \
  --output json | tee "$OUTPUT_DIR/scps.json"

echo
echo "SCPs:"
aws organizations list-policies \
  --filter SERVICE_CONTROL_POLICY \
  --query 'Policies[].{Name:Name,Id:Id,Arn:Arn,AwsManaged:AwsManaged}' \
  --output table

echo


# ------------------------------------------------------------
# 7. SCP attachments to Root
# ------------------------------------------------------------

echo "[7/12] Getting Root SCP attachments..."

aws organizations list-policies-for-target \
  --target-id "$ROOT_ID" \
  --filter SERVICE_CONTROL_POLICY \
  --output json | tee "$OUTPUT_DIR/root-scp-attachments.json"

echo
echo "Root SCP attachments:"
aws organizations list-policies-for-target \
  --target-id "$ROOT_ID" \
  --filter SERVICE_CONTROL_POLICY \
  --query 'Policies[].{Name:Name,Id:Id,Arn:Arn}' \
  --output table

echo


# ------------------------------------------------------------
# 8. Control Tower Landing Zone
# ------------------------------------------------------------

echo "[8/12] Getting Control Tower Landing Zone..."

aws controltower list-landing-zones \
  --region "$REGION" \
  --output json | tee "$OUTPUT_DIR/landing-zones.json"

LANDING_ZONE_ID=$(aws controltower list-landing-zones \
  --region "$REGION" \
  --query 'landingZones[0].arn' \
  --output text 2>/dev/null || true)

echo
echo "Landing Zone:"
cat "$OUTPUT_DIR/landing-zones.json"
echo


# ------------------------------------------------------------
# 9. Control Tower Controls
# ------------------------------------------------------------

echo "[9/12] Getting Control Tower enabled controls..."

aws controltower list-enabled-controls \
  --region "$REGION" \
  --output json | tee "$OUTPUT_DIR/controltower-controls.json"

echo


# ------------------------------------------------------------
# 10. IAM Identity Center
# ------------------------------------------------------------

echo "[10/12] Getting IAM Identity Center instance..."

aws sso-admin list-instances \
  --region "$REGION" \
  --output json | tee "$OUTPUT_DIR/identity-center.json"

INSTANCE_ARN=$(aws sso-admin list-instances \
  --region "$REGION" \
  --query 'Instances[0].InstanceArn' \
  --output text)

IDENTITY_STORE_ID=$(aws sso-admin list-instances \
  --region "$REGION" \
  --query 'Instances[0].IdentityStoreId' \
  --output text)

echo
echo "Instance ARN      : $INSTANCE_ARN"
echo "Identity Store ID : $IDENTITY_STORE_ID"
echo


# ------------------------------------------------------------
# 11. IAM Identity Center Permission Sets
# ------------------------------------------------------------

echo "[11/12] Getting Permission Sets..."

if [[ "$INSTANCE_ARN" != "None" && -n "$INSTANCE_ARN" ]]; then

    aws sso-admin list-permission-sets \
      --instance-arn "$INSTANCE_ARN" \
      --region "$REGION" \
      --output json | tee "$OUTPUT_DIR/permission-sets.json"

    echo
    echo "Permission Sets:"
    aws sso-admin list-permission-sets \
      --instance-arn "$INSTANCE_ARN" \
      --region "$REGION" \
      --query 'PermissionSets[]' \
      --output table

fi

echo


# ------------------------------------------------------------
# 12. IAM Identity Center Users
# ------------------------------------------------------------

echo "[12/12] Getting IAM Identity Center users..."

if [[ "$IDENTITY_STORE_ID" != "None" && -n "$IDENTITY_STORE_ID" ]]; then

    aws identitystore list-users \
      --identity-store-id "$IDENTITY_STORE_ID" \
      --region "$REGION" \
      --output json | tee "$OUTPUT_DIR/users.json"

    echo
    echo "Users:"
    aws identitystore list-users \
      --identity-store-id "$IDENTITY_STORE_ID" \
      --region "$REGION" \
      --query 'Users[].{UserName:UserName,UserId:UserId,DisplayName:DisplayName,Email:Emails[0].Value}' \
      --output table

fi

echo
echo "============================================================"
echo " VALIDATION COMPLETE"
echo "============================================================"
echo
echo "AWS Account       : $ACCOUNT_ID"
echo "Caller            : $CALLER_ARN"
echo "Organization      : $ORG_ID"
echo "Root              : $ROOT_ID"
echo "Identity Center   : $INSTANCE_ARN"
echo "Identity Store    : $IDENTITY_STORE_ID"
echo
echo "Inventory files:"
find "$OUTPUT_DIR" -maxdepth 1 -type f -print | sort
echo
echo "No AWS resources were modified."
echo "============================================================"
