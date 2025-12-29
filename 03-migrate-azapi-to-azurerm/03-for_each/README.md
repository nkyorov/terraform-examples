# For_Each Migration Scenario

This scenario demonstrates how to migrate resources created using the `for_each` meta-argument from the `azapi` provider to the `azurerm` provider.

The biggest limitation of `count` is that it identifies resources by their position in a list (index 0, 1, 2...). If you remove a resource from the middle of a list, Terraform shifts the indices of every subsequent resource. This causes Terraform to destroy and recreate resources that haven't actually changed.

Objects are commonly used with `for_each` blocks to solve this. This allows you to define a "schema" for your resources where each instance is identified by a unique string key (e.g., "frontend", "backend") rather than a numeric index.

> [!TIP]
> `for_each` is generally the preferred choice for production infrastructure because it is more stable than `count` when resources are added or removed.

## Repository Structure

The following table describes the purpose of each file used in this scenario.

| File Name             | Description                                                       |
| --------------------- | ----------------------------------------------------------------- |
| `before-migration.tf` | Shows the Terraform configuration before starting the migration.  |
| `after-migration.tf`  | Shows the Terraform configuration after completing the migration. |
| `providers.tf`        | Defines the required Terraform providers and their configuration. |
| `variables.tf`        | Declares input variables used across the configuration.           |

> [!NOTE]
> The *before* and *after* configurations are **not separate files** in practice. They represent the state of the configuration **at the start** and **at the end** of the migration. They are provided separately here for clarity.

## Walkthrough

### 1. Before Migration
To set up the initial environment, we deploy a Resource Group, a Virtual Network, and multiple Subnets using `azapi` with the `for_each` meta-argument.

```hcl
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
```

### 2. Migration Steps

To migrate these resources, we must define the new `azurerm` resource using the same `for_each` configuration (referencing `var.subnets`).

```hcl
resource "azurerm_subnet" "main" {
  for_each             = var.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.address_prefix]
}
```

---

Next, we remove the `azapi` resource from Terraform's state using the `removed` block.

```hcl
removed {
  from = azapi_resource.subnets
  lifecycle {
    destroy = false 
  }
}

# The original resource must be removed or commented out to avoid conflicts
# resource "azapi_resource" "subnets" {
#   for_each  = var.subnets
#   ...
# }
```

> [!IMPORTANT]
> Always set `destroy = false` in the `lifecycle` block. This ensures Terraform removes the resource from the state file but leaves the actual infrastructure running in Azure.

If you do not remove or comment out the original `azapi` code, Terraform will error:

```text
│ Error: Removed resource still exists
│ 
│ This statement declares that azapi_resource.subnets was removed, but it is still declared in configuration.
```

---

### 3. Import the Resources

When importing resources that use `for_each`, we need to map a specific Azure Resource ID to a specific Terraform **map key**.

We use the `for_each` argument inside the `import` block to iterate over the Resource IDs and assign them to the correct key (e.g., `azurerm_subnet.main["frontend"]`).

```hcl
import {
  for_each = {
    "/subscriptions/.../virtualNetworks/vnet-azapi-migration/subnets/frontend" = "frontend"
    "/subscriptions/.../virtualNetworks/vnet-azapi-migration/subnets/backend"  = "backend"
  }

  id = each.key
  to = azurerm_subnet.main[each.value]
}
```

> [!TIP]
>You can also define resource ids in a `locals` block:
>
> ```hcl
> locals {
>   resources_to_import = {
>     "<resource-id-1>" = "frontend"
>     "<resource-id-2>" = "backend"
>   }
> }
> 
> import {
>   for_each = local.resources_to_import
>   id       = each.key
>   to       = azurerm_subnet.main[each.value]
> }
> ```

### 4. Verification

To check our work, we run `terraform plan`. Terraform should indicate that the resources will be imported and the old `azapi` tracking information for the named keys will be discarded.

```sh
$ terraform plan
...
Plan: 2 to import, 0 to add, 0 to change, 0 to destroy.

│ Warning: Some objects will no longer be managed by Terraform
│ 
│ If you apply this plan, Terraform will discard its tracking information for the following objects, but it will not delete them:
│  - azapi_resource.subnets["frontend"]
│  - azapi_resource.subnets["backend"]
│ 
│ After applying this plan, Terraform will no longer manage these objects. You will need to import them into Terraform to manage them again.
```

Apply the configuration:

```sh
$ terraform apply
...
Apply complete! Resources: 2 imported, 0 added, 0 changed, 0 destroyed.
```