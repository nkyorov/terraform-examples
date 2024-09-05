locals {
  raw_data = jsondecode(file("${path.module}/${var.json_file_path}"))

  # You can also set default values by utilising a local
  rg_data = {
    name     = local.raw_data.name
    location = try(local.raw_data.location, "westeurope")
    tags     = try(local.raw_data.tags, {})
  }
}

resource "azurerm_resource_group" "jsondecode" {
  name     = local.rg_data.name
  location = local.rg_data.location

  tags = local.rg_data.tags
}

output "rg_data" {
  value = local.rg_data
}