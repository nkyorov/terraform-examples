resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

removed {
  from = azapi_resource.managed_identity
  lifecycle {
    destroy = false # remove the resource from state without destroying the actual resource
  }
}

# We need to comment out/remove this, otherwise Terraform will throw an error message
# resource "azapi_resource" "managed_identity" {
#   type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
#   name      = var.managed_identity_name
#   location  = var.location
#   parent_id = azurerm_resource_group.main.id
# }

import {
  id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{userAssignedIdentityName}"
  to = azurerm_user_assigned_identity.main
}

resource "azurerm_user_assigned_identity" "main" {
  location            = azurerm_resource_group.main.location
  name                = var.managed_identity_name
  resource_group_name = azurerm_resource_group.main.name
}