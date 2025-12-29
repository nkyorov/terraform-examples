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

resource "azapi_resource" "subnets" {
  for_each  = var.subnets
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-09-01"
  name      = each.key
  parent_id = azurerm_virtual_network.main.id

  body = {
    properties = {
      addressPrefix = each.value.address_prefix
    }
  }
}