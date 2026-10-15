# ============================================================
# Azure Migration Lab - Resource ID Inventory
# Resource Group: rg-migration-lab
# Region: Central India
# ============================================================

RESOURCE_GROUP="rg-migration-lab"
SUBSCRIPTION_ID="440b48d6-073f-4588-9499-24c49906a898"

az account set --subscription "$SUBSCRIPTION_ID"

echo ""
echo "========== AZURE ACCOUNT =========="
az account show \
  --query "{subscription:name,subscriptionId:id,tenantId:tenantId}" \
  -o table

echo ""
echo "========== ALL RESOURCE IDS =========="
az resource list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{Name:name,Type:type,Location:location,ResourceId:id}" \
  -o table

echo ""
echo "========== RESOURCE GROUP ID =========="
az group show \
  --name "$RESOURCE_GROUP" \
  --query "{name:name,id:id,location:location}" \
  -o json

echo ""
echo "========== VNET AND SUBNET IDS =========="
az network vnet show \
  --resource-group "$RESOURCE_GROUP" \
  --name "vnet-migration" \
  --query "{name:name,id:id,addressSpace:addressSpace.addressPrefixes,subnets:subnets[].{name:name,id:id,prefix:addressPrefix}}" \
  -o json

echo ""
echo "========== NETWORK SECURITY GROUP IDS =========="
az network nsg list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{name:name,id:id,location:location}" \
  -o table

echo ""
echo "========== ROUTE TABLE IDS =========="
az network route-table list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{name:name,id:id,location:location,subnets:subnets[].id}" \
  -o json

echo ""
echo "========== VPN GATEWAY =========="
az network vnet-gateway show \
  --resource-group "$RESOURCE_GROUP" \
  --name "vng-migration" \
  --query "{name:name,id:id,location:location,sku:sku.name,gatewayType:gatewayType,vpnType:vpnType,publicIPs:ipConfigurations[].{name:name,publicIPId:publicIPAddress.id,subnetId:subnet.id}}" \
  -o json

echo ""
echo "========== VPN PUBLIC IP =========="
az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "pip-vpn-migration" \
  --query "{name:name,id:id,ipAddress:ipAddress,sku:sku.name,allocation:publicIPAllocationMethod}" \
  -o json

echo ""
echo "========== AWS LOCAL NETWORK GATEWAY =========="
az network local-gateway show \
  --resource-group "$RESOURCE_GROUP" \
  --name "lng-aws-migration-tunnel1" \
  --query "{name:name,id:id,gatewayIpAddress:gatewayIpAddress,addressPrefixes:localNetworkAddressSpace.addressPrefixes,bgpSettings:bgpSettings}" \
  -o json

echo ""
echo "========== VPN CONNECTION =========="
az network vpn-connection show \
  --resource-group "$RESOURCE_GROUP" \
  --name "connection-aws-migration-tunnel1" \
  --query "{name:name,id:id,connectionType:connectionType,connectionStatus:connectionStatus,virtualNetworkGateway1Id:virtualNetworkGateway1.id,localNetworkGateway2Id:localNetworkGateway2.id}" \
  -o json

echo ""
echo "========== INVENTORY COMPLETE =========="
