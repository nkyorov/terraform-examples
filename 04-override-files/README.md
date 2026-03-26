# Override Files
## What are Override Files?
Terraform normally loads all of the `.tf` and `.tf.json` files within a directory and expects each one to define a distinct set of configuration objects. If two files attempt to define the same object, Terraform returns an error.

Override files are the intentional exception to this rule: you can override specific portions of an existing configuration object in a separate file.

Terraform initially skips these override files when loading configuration, processes them last and tries to merge the override blocks into the existing object.

### Naming Conventions
Any file ending in `*_override.tf/` and `*_override.tf.json`, or those named exactly `override.tf` and `override.tf.json` is treated as an override file. 

- `override.tf/override.tf.json` - processed first 
- `*_override.tf/*_override.tf.json` - processed in alphabetical order after `override.tf/override.tf.json`

### How Merging Works
Generally speaking, matching an original block (type and name):

- an attribute argument within an override block replaces any argument of the same name in the original block
- any nested blocks within an override block replace all blocks of the same type in the original block
- any block types that do not appear in the override block remain from the original block
- The contents of nested configuration blocks are not merged.

> [!NOTE]
> Validation rules that apply to the given block type still apply to the final merged block.

## Use Cases
### Reconfiguring Resource Attributes
Here's how our original configuration (`main.tf`) and `override.tf` look like:
```
# main.tf
resource "azurerm_storage_account" "tfs" {
  name                     = "storageaccountname"
  account_replication_type = "GRS"
}

# override.tf
resource "azurerm_storage_account" "tfs" {
  account_replication_type = "LRS"
}
```

Terraform will merge `override.tf` into `main.tf`, making the configuration effectively this:

```
resource "azurerm_storage_account" "tfs" {
  name                     = "storageaccountname"
  account_replication_type = "LRS"
}
```

### Reconfigure State Backend For Development And Testing
```
# terraform.tf
terraform {
  backend "azurerm" {
      resource_group_name  = "tfstate"
      storage_account_name = "<storage_account_name>"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }
}

# terraform_override.tf
terraform {
  backend "local" {
    path = "relative/path/to/terraform.tfstate"
  }
}
```

### Developing Modules Locally
You might want to use a local copy instead of a remote source:

```
# vnet.tf
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"
}

# vnet_override.tf (use local module during development)
module "vpc" {
  source = "../avm-res-network-virtualnetwork"
}
```

### Overriding Variable Defaults
When overriding variables, Terraform enforces compatibility between the type and the default value:

- **If you change the type**: Terraform attempts to convert the original default value to the new type.
- **If you change the default value**: The new value must match the original type definition.
In either scenario, if the new configuration is incompatible, Terraform will return an error.

```
# variables.tf
variable "vm_size" {
  type    = string
  default = "Standard_F2"
}

# variables_override.tf
variable "vm_size" {
  default = "Standard_B2s"
}
```

# Best Practices
- Do not consider this a pattern: **avoid** if you don't really need it
- For local development and testing, add override files to `.gitignore`
- Document everything, as readability takes a huge hit: leave comments in the original configuration files about which overrides applies to each block