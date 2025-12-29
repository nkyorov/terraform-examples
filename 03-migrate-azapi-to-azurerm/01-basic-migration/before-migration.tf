resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azapi_resource" "managed_identity" {
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  name      = var.managed_identity_name
  location  = var.location
  parent_id = azurerm_resource_group.main.id
}