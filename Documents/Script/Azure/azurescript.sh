#!/bin/bash

set -e

SUBSCRIPTION_ID="440b48d6-073f-4588-9499-24c49906a898"
RESOURCE_GROUP="rg-hybrid-networking"
LOCATION="centralindia"

echo "============================================================"
echo " Azure Hybrid Networking Inventory"
echo "============================================================"
echo "Subscription : $SUBSCRIPTION_ID"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location      : $LOCATION"
echo "============================================================"

az account set --subscription "$SUBSCRIPTION_ID"

echo
echo "============================================================"
echo "1. RESOURCE GROUP"
echo "============================================================"

az group show \
  --name "$RESOURCE_GROUP" \
  --query '{
    id:id,
    name:name,
    location:location,
    provisioningState:properties.provisioningState,
    tags:tags
  }' \
  -o json

echo
echo "============================================================"
echo "2. ALL RESOURCES IN RESOURCE GROUP"
echo "============================================================"

az resource list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].{
    name:name,
    type:type,
    id:id,
    location:location
  }' \
  -o table

echo
echo "============================================================"
echo "3. VNET"
echo "============================================================"

az network vnet list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].{
    name:name,
    id:id,
    location:location,
    addressSpace:properties.addressSpace.addressPrefixes,
    provisioningState:properties.provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "4. SUBNETS"
echo "============================================================"

VNET_NAME="vnet-hybrid-azure"

az network vnet subnet list \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --query '[].{
    name:name,
    id:id,
    addressPrefix:properties.addressPrefix,
    addressPrefixes:properties.addressPrefixes,
    routeTable:properties.routeTable.id,
    networkSecurityGroup:properties.networkSecurityGroup.id,
    provisioningState:properties.provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "5. PUBLIC IP ADDRESSES"
echo "============================================================"

az network public-ip list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].{
    name:name,
    id:id,
    ipAddress:properties.ipAddress,
    allocationMethod:properties.publicIPAllocationMethod,
    sku:sku.name,
    zones:zones,
    location:location,
    provisioningState:properties.provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "6. VPN GATEWAYS"
echo "============================================================"

az network vnet-gateway list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].{
    name:name,
    id:id,
    location:location,
    gatewayType:properties.gatewayType,
    vpnType:properties.vpnType,
    sku:name,
    activeActive:properties.activeActive,
    enableBgp:properties.enableBgp,
    bgpSettings:properties.bgpSettings,
    ipConfigurations:properties.ipConfigurations,
    provisioningState:properties.provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "7. LOCAL NETWORK GATEWAYS"
echo "============================================================"

az network local-gateway list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].{
    name:name,
    id:id,
    location:location,
    gatewayIpAddress:properties.gatewayIpAddress,
    localNetworkAddressSpace:properties.localNetworkAddressSpace.addressPrefixes,
    bgpSettings:properties.bgpSettings,
    provisioningState:properties.provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "8. VPN CONNECTIONS"
echo "============================================================"

az network vpn-connection list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].{
    name:name,
    id:id,
    location:location,
    connectionType:properties.connectionType,
    connectionStatus:properties.connectionStatus,
    enableBgp:properties.enableBgp,
    vpnGateway1:properties.vpnGateway1.id,
    localNetworkGateway2:properties.localNetworkGateway2.id,
    sharedKey:properties.sharedKey,
    provisioningState:properties.provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "9. NETWORK SECURITY GROUPS"
echo "============================================================"

az network nsg list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].{
    name:name,
    id:id,
    location:location,
    provisioningState:properties.provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "10. NSG SECURITY RULES"
echo "============================================================"

for NSG in $(az network nsg list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].name' \
  -o tsv); do

  echo
  echo "--------------- NSG: $NSG ---------------"

  az network nsg rule list \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG" \
    --query '[].{
      name:name,
      priority:priority,
      direction:direction,
      access:access,
      protocol:protocol,
      sourceAddressPrefix:sourceAddressPrefix,
      sourcePortRange:sourcePortRange,
      destinationAddressPrefix:destinationAddressPrefix,
      destinationPortRange:destinationPortRange
    }' \
    -o table
done

echo
echo "============================================================"
echo "11. NICs"
echo "============================================================"

az network nic list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].{
    name:name,
    id:id,
    location:location,
    privateIp:properties.ipConfigurations[0].properties.privateIPAddress,
    subnet:properties.ipConfigurations[0].properties.subnet.id,
    publicIp:properties.ipConfigurations[0].properties.publicIPAddress.id,
    nsg:properties.networkSecurityGroup.id,
    provisioningState:properties.provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "12. VIRTUAL MACHINES"
echo "============================================================"

az vm list \
  --resource-group "$RESOURCE_GROUP" \
  --show-details \
  --query '[].{
    name:name,
    id:id,
    location:location,
    vmSize:hardwareProfile.vmSize,
    privateIp:privateIps,
    publicIp:publicIps,
    powerState:powerState,
    provisioningState:provisioningState
  }' \
  -o json

echo
echo "============================================================"
echo "13. VPN GATEWAY CONNECTION DETAILS"
echo "============================================================"

for VPNGW in $(az network vnet-gateway list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].name' \
  -o tsv); do

  echo
  echo "--------------- VPN Gateway: $VPNGW ---------------"

  az network vnet-gateway show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VPNGW" \
    -o json
done

echo
echo "============================================================"
echo "14. VPN CONNECTION DETAILS"
echo "============================================================"

for CONN in $(az network vpn-connection list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].name' \
  -o tsv); do

  echo
  echo "--------------- Connection: $CONN ---------------"

  az network vpn-connection show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONN" \
    -o json
done

echo
echo "============================================================"
echo "15. COMPLETE RESOURCE ID LIST"
echo "============================================================"

az resource list \
  --resource-group "$RESOURCE_GROUP" \
  --query '[].id' \
  -o tsv

echo
echo "============================================================"
echo " INVENTORY COMPLETE"
echo "============================================================"
