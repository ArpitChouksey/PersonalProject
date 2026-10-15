
#!/bin/bash

set -u

SUBSCRIPTION_ID="440b48d6-073f-4588-9499-24c49906a898"

# Only these resource groups are targeted.
RESOURCE_GROUPS=(
  "rg-migration-lab"
  "aws_211811255273"
)

echo "=========================================="
echo " Azure Lab Cleanup"
echo "=========================================="

# Verify Azure CLI login and subscription
if ! az account show >/dev/null 2>&1; then
  echo "ERROR: Please run az login first."
  exit 1
fi

az account set --subscription "$SUBSCRIPTION_ID" || exit 1

CURRENT_SUB=$(az account show --query id -o tsv)

if [ "$CURRENT_SUB" != "$SUBSCRIPTION_ID" ]; then
  echo "ERROR: Subscription mismatch. Aborting."
  exit 1
fi

echo "Subscription:"
az account show --query "{Name:name,ID:id}" -o table

echo ""
echo "Reviewing target resource groups..."

FOUND_GROUPS=()

for RG in "${RESOURCE_GROUPS[@]}"; do
  echo ""
  echo "========== $RG =========="

  if az group show --name "$RG" >/dev/null 2>&1; then
    FOUND_GROUPS+=("$RG")

    az group show \
      --name "$RG" \
      --query "{Name:name,Location:location,State:properties.provisioningState}" \
      -o table

    echo "Resources that will be deleted:"
    az resource list \
      --resource-group "$RG" \
      --query "[].{Name:name,Type:type,Location:location}" \
      -o table
  else
    echo "Not found; skipping."
  fi
done

if [ "${#FOUND_GROUPS[@]}" -eq 0 ]; then
  echo ""
  echo "No target resource groups remain."
  exit 0
fi

echo ""
echo "WARNING: Every resource in the listed groups will be deleted."
echo "Review the inventory above before proceeding."
printf 'Type DELETE to continue: '
read -r CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
  echo "Cancelled. No deletion requested."
  exit 0
fi

for RG in "${FOUND_GROUPS[@]}"; do
  echo ""
  echo "Deleting resource group: $RG"

  if az group show --name "$RG" >/dev/null 2>&1; then
    if az group delete \
      --name "$RG" \
      --subscription "$SUBSCRIPTION_ID" \
      --yes; then
      echo "Deletion command completed for $RG."
    else
      echo "ERROR: Deletion failed for $RG."
      echo "Check Azure Activity Log, resource locks, and dependencies."
    fi
  else
    echo "$RG has already disappeared; skipping."
  fi
done

echo ""
echo "=========================================="
echo " Final verification"
echo "=========================================="

for RG in "${RESOURCE_GROUPS[@]}"; do
  if az group show --name "$RG" >/dev/null 2>&1; then
    echo "STILL EXISTS or deletion is incomplete: $RG"
  else
    echo "Not found: $RG"
  fi
done

echo ""
echo "Check the Azure Cost Management page for remaining charges."

