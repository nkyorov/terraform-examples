# Count Migration Scenario

This scenario demonstrates how to migrate multiple resources created using the `count` meta-argument from the `azapi` provider to the `azurerm` provider.

In Terraform, the `count` meta-argument allows you to create *N* identical resources based on a numeric value. Each resource is indexed starting at 0, meaning specific instances are referenced using `resource_name[index]`:
- `azapi_resource.example[0]`
- `azapi_resource.example[1]`
- `azapi_resource.example[2]`

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
To set up the initial environment, we deploy a Resource Group and three User Assigned Managed Identities using the `count` meta-argument.

```hcl
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azapi_resource" "managed_identity" {
  count     = 3

  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  name      = "${var.managed_identity_name}-${count.index}"
  location  = var.location
  parent_id = azurerm_resource_group.main.id
}
```

Once applied, we have three distinct resources indexed `[0]`, `[1]`, and `[2]`.

### 2. Migration Steps

To migrate these resources, we must define the new `azurerm` resource with the same `count` configuration.

```hcl
resource "azurerm_user_assigned_identity" "main" {
  count               = 3

  location            = azurerm_resource_group.main.location
  name                = "${var.managed_identity_name}-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
}
```

---

Next, we remove the `azapi` resource from Terraform's state using the `removed` block.

```hcl
removed {
  from = azapi_resource.managed_identity
  lifecycle {
    destroy = false 
  }
}

# We need to comment out or remove the original resource to avoid conflicts
# resource "azapi_resource" "managed_identity" {
#   count     = 3
#   ...
# }
```

> [!IMPORTANT]
> Always set `destroy = false` in the `lifecycle` block. This ensures Terraform removes the resource from the state file but leaves the actual infrastructure running in Azure.

If you do not remove or comment out the original `azapi` code, Terraform will error:

```text
│ Error: Removed resource still exists
│ 
│ This statement declares that azapi_resource.managed_identity was removed, but it is still declared in configuration.
```

---

### 3. Import the Resources

When importing resources that use `count`, we need to map a specific Azure Resource ID to a specific Terraform index.

We use the `for_each` argument inside the `import` block to iterate over the Resource IDs and assign them to the correct index (e.g., `azurerm_user_assigned_identity.main[0]`).

```hcl
import {
  for_each = {
    "/subscriptions/{subId}/.../userAssignedIdentities/{name}-0" = 0
    "/subscriptions/{subId}/.../userAssignedIdentities/{name}-1" = 1
    "/subscriptions/{subId}/.../userAssignedIdentities/{name}-2" = 2
  }

  id = each.key
  to = azurerm_user_assigned_identity.main[each.value]
}
```

> [!TIP]
>You can also define resource ids in a `locals` block:
>
> ```hcl
> locals {
>   resources_to_import = {
>     "/subscriptions/.../resource-0" = 0
>     "/subscriptions/.../resource-1" = 1
>   }
> }
> 
> import {
>   for_each = local.resources_to_import
>   id       = each.key
>   to       = azurerm_user_assigned_identity.main[each.value]
> }
> ```

### 4. Verification

To check our work, we run `terraform plan`. Terraform should indicate that 3 resources will be imported and the old `azapi` tracking information will be discarded.

```sh
$ terraform plan
...
Plan: 3 to import, 0 to add, 0 to change, 0 to destroy.

│ Warning: Some objects will no longer be managed by Terraform
│ 
│ If you apply this plan, Terraform will discard its tracking information for the following objects, but it will not delete them:
│  - azapi_resource.managed_identity[1]
│  - azapi_resource.managed_identity[0]
│  - azapi_resource.managed_identity[2]
│ 
│ After applying this plan, Terraform will no longer manage these objects. You will need to import them into Terraform to manage them again.
```

Apply the configuration:

```sh
$ terraform apply
...
Apply complete! Resources: 3 imported, 0 added, 0 changed, 0 destroyed.
```

On the subsequent run, Terraform should report no changes:

```sh
$ terraform apply
...
No changes. Your infrastructure matches the configuration.
```