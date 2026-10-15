import {
  to = module.resource_group.azurerm_resource_group.this
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab"
}

import {
  to = module.networking.azurerm_virtual_network.this
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworks/vnet-migration"
}

import {
  to = module.networking.azurerm_subnet.this["GatewaySubnet"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworks/vnet-migration/subnets/GatewaySubnet"
}

import {
  to = module.networking.azurerm_subnet.this["ApplicationSubnet"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworks/vnet-migration/subnets/ApplicationSubnet"
}

import {
  to = module.networking.azurerm_subnet.this["DatabaseSubnet"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworks/vnet-migration/subnets/DatabaseSubnet"
}

import {
  to = module.network_security_group.azurerm_network_security_group.this["nsg-application"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-application"
}

import {
  to = module.network_security_group.azurerm_network_security_group.this["nsg-database"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-database"
}

import {
  to = module.route_table.azurerm_route_table.this["rt-application"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/routeTables/rt-application"
}

import {
  to = module.route_table.azurerm_route_table.this["rt-database"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/routeTables/rt-database"
}

import {
  to = module.networking.azurerm_subnet_network_security_group_association.this["ApplicationSubnet"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworks/vnet-migration/subnets/ApplicationSubnet"
}

import {
  to = module.networking.azurerm_subnet_network_security_group_association.this["DatabaseSubnet"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworks/vnet-migration/subnets/DatabaseSubnet"
}

import {
  to = module.networking.azurerm_subnet_route_table_association.this["ApplicationSubnet"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworks/vnet-migration/subnets/ApplicationSubnet"
}

import {
  to = module.networking.azurerm_subnet_route_table_association.this["DatabaseSubnet"]
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworks/vnet-migration/subnets/DatabaseSubnet"
}

# Import existing Azure VPN connectivity resources
import {
  to = module.vpn_connectivity.azurerm_public_ip.this
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/publicIPAddresses/pip-vpn-migration"
}

import {
  to = module.vpn_connectivity.azurerm_virtual_network_gateway.this
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/virtualNetworkGateways/vng-migration"
}

import {
  to = module.vpn_connectivity.azurerm_local_network_gateway.this
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/localNetworkGateways/lng-aws-migration-tunnel1"
}

import {
  to = module.vpn_connectivity.azurerm_virtual_network_gateway_connection.this
  id = "/subscriptions/440b48d6-073f-4588-9499-24c49906a898/resourceGroups/rg-migration-lab/providers/Microsoft.Network/connections/connection-aws-migration-tunnel1"
}
