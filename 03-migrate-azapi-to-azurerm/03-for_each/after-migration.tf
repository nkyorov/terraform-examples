resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.virtual_network.address_space
  dns_servers         = var.virtual_network.dns_servers
}

removed {
  from = azapi_resource.subnets
  lifecycle {
    destroy = false # remove the resource from state without destroying the actual resource
  }
}

# We need to comment out/remove this, otherwise Terraform will throw an error message
# resource "azapi_resource" "subnets" {
#   for_each  = var.subnets
#   type      = "Microsoft.Network/virtualNetworks/subnets@2023-09-01"
#   name      = each.key
#   parent_id = azurerm_virtual_network.main.id

#   body = {
#     properties = {
#       addressPrefix = each.value.address_prefix
#     }
#   }
# }

import {
  for_each = {
    "/subscriptions/6fba1f50-3cf6-4ef7-a0c1-9b596bef4b86/resourceGroups/rg-azapi-migration/providers/Microsoft.Network/virtualNetworks/vnet-azapi-migration/subnets/frontend"  = "frontend"
    "/subscriptions/6fba1f50-3cf6-4ef7-a0c1-9b596bef4b86/resourceGroups/rg-azapi-migration/providers/Microsoft.Network/virtualNetworks/vnet-azapi-migration/subnets/backend"   = "backend"
  }

  id = each.key
  to = azurerm_subnet.main[each.value]
}

resource "azurerm_subnet" "main" {
  for_each             = var.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.address_prefix]
}