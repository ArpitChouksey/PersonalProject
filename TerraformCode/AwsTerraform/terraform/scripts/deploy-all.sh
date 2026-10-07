#!/bin/bash

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=========================================="
echo " Enterprise Terraform Deployment"
echo "=========================================="

run_terraform() {
    local DIR="$1"

    echo ""
    echo "=========================================="
    echo "Processing: $DIR"
    echo "=========================================="

    cd "$ROOT/$DIR"

    terraform init
    terraform validate
    terraform plan

    read -p "Apply $DIR? (yes/no): " CONFIRM

    if [ "$CONFIRM" = "yes" ]; then
        terraform apply -auto-approve
    else
        echo "Skipping $DIR"
    fi
}

# ------------------------------------------------------------
# Phase 1 - Organization
# ------------------------------------------------------------

run_terraform "org"

# ------------------------------------------------------------
# Phase 2 - Control Tower
# ------------------------------------------------------------

run_terraform "control-tower"

# ------------------------------------------------------------
# Phase 3 - Identity Center
# ------------------------------------------------------------

run_terraform "identity-center"

# ------------------------------------------------------------
# Phase 4 - Account Baselines
# ------------------------------------------------------------

for ACCOUNT in \
    management \
    security \
    log-archive \
    network \
    shared-services \
    production \
    non-production
do
    run_terraform "accounts/$ACCOUNT/us-east-1"
done

echo ""
echo "=========================================="
echo " Deployment completed"
echo "=========================================="
