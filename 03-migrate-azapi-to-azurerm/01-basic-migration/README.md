# Simple Migration Scenario

This scenario demonstrates how to migrate a **single resource** from the `azapi` provider to the `azurerm` provider. It utilizes a combination of `removed` and `import` blocks to transition management without re-deploying or impacting existing infrastructure.

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
To set up the initial environment, we will deploy two resources:
- One Resource Group (`azurerm` provider)
- One User Assigned Managed Identity (`azapi` provider)

```hcl
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
```

Once these resources are applied, we are ready to migrate the Managed Identity to the `azurerm` provider.

### 2. Migration Steps

First, identify the corresponding `azurerm` resource. in this case, it is `azurerm_user_assigned_identity`.

Since this resource requires minimal configuration, we only need to match the *location*, *name*, and *resource_group_name* to the values defined in the `azapi_resource`.

> [!NOTE]
> If there is a mismatch between AzureRM's and AzAPI's default values, you must either include the additional parameters to match the AzAPI value or use the `ignore_changes` lifecycle argument to suppress plan differences.

---

Once the new resource definition is added to the configuration, we must remove the AzAPI resource from Terraform's management. We will use a `removed` block for this purpose. 

The `removed` block allows you to remove a resource from the Terraform state without destroying the actual cloud resource.

```hcl
removed {
  from = azapi_resource.managed_identity
  lifecycle {
    destroy = false 
  }
}

# The original resource must be removed or commented out to avoid conflicts
# resource "azapi_resource" "managed_identity" {
#   type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
#   name      = var.managed_identity_name
#   location  = var.location
#   parent_id = azurerm_resource_group.main.id
# }
```

> [!IMPORTANT]
> By default, Terraform removes the resource from the state file **and destroys** the actual infrastructure.
>
> You must use the `lifecycle` meta-argument and set `destroy` to `false` to keep the infrastructure running while removing it from the Terraform state.

If you fail to remove or comment out the original resource definition, Terraform will return an error:

```text
│ Error: Removed resource still exists
│ 
│   on after-migration.tf line 13:
│   13: resource "azapi_resource" "managed_identity" {
│ 
│ This statement declares that azapi_resource.managed_identity was removed, but it is still declared in configuration.
```

---

### 3. Import the Resource

As a final step, we define the `import` block to bring the existing resource under the management of the new `azurerm` resource definition.

```hcl
import {
  id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{userAssignedIdentityName}"
  to = azurerm_user_assigned_identity.main
}

resource "azurerm_user_assigned_identity" "main" {
  location            = azurerm_resource_group.main.location
  name                = var.managed_identity_name
  resource_group_name = azurerm_resource_group.main.name
}
```

> [!NOTE]
> Ensure you use the correct Resource ID. You can retrieve this via the Azure Portal, Azure CLI, or by constructing the ID string manually. For more details, reference the HashiCorp documentation for the specific resource.

### 4. Verification

To check the migration logic, run `terraform plan`:

```sh
$ terraform plan
...
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.

│ Warning: Some objects will no longer be managed by Terraform
│
│ If you apply this plan, Terraform will discard its tracking information for
│ the following objects, but it will not delete them:
│  - azapi_resource.managed_identity
│
│ After applying this plan, Terraform will no longer manage these objects.
│ You will need to import them into Terraform to manage them again.
```

Apply the configuration by running `terraform apply`:

```sh
$ terraform apply
...
Apply complete! Resources: 1 imported, 0 added, 0 changed, 0 destroyed.
```

On the subsequent run, Terraform should report no changes:

```sh
$ terraform apply
...
No changes. Your infrastructure matches the configuration.
```