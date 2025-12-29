# Migration from AzAPI to AzureRM Provider

This repository demonstrates how to migrate resources from the **AzAPI** provider to the **AzureRM** provider with little to no impact on existing infrastructure.

## Why?

Not all Azure features—even those in General Availability (GA)—are immediately available in the `azurerm` provider.

The recommended alternative is the **AzAPI** provider. It is a very thin layer on top of the Azure ARM REST APIs that allows you to manage Azure resources that are not yet (or may never be) supported in the AzureRM provider, such as private/public preview services and features.

## The Problem with `moved` Blocks

Normally, we use a `moved` block to change a resource's address programmatically:

```hcl
moved {
  from = azapi_resource.example
  to   = azurerm_resource_group.example
}
```

Unfortunately, this approach **does not work** when migrating between different provider resource types. You will encounter an error like this:

```text
│ Error: Move Resource State Not Supported
│
│ The "azurerm_resource_group" resource type does not support moving 
│ resource state across resource types.
```

## The Solution

To achieve this migration, we use a combination of two Terraform features:

1.  **`removed` block (Terraform v1.7+):** Programmatically removes a resource from the state without destroying the real infrastructure.
2.  **`import` block (Terraform v1.5+):** Programmatically imports an existing resource into the state.

We will look at several migration scenarios:

| Scenario                                             | Description                                                                              |
| :--------------------------------------------------- | :--------------------------------------------------------------------------------------- |
| [Simple Configuration](01-basic-migration/README.md) | Migrates a single AzAPI-managed resource to AzureRM using `removed` and `import` blocks. |
| [`Count` Configuration](02-count/README.md)          | Migrates multiple indexed resources created with the `count` meta-argument.              |
| [`For_Each` Configuration](03-for_each/README.md)    | Migrates key-based resources created with the `for_each` meta-argument.                  |

