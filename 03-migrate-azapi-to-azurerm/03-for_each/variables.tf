variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-azapi-migration"
}

variable "virtual_network" {
  description = "Configuration for the virtual network."
  type = object({
    name          = string
    address_space = list(string)
    dns_servers   = list(string)
  })
  default = {
    name = "vnet-azapi-migration"
    address_space = ["10.0.0.0/16"]
    dns_servers = ["10.0.0.4", "10.0.0.5"]
  }
}

variable "subnets" {
  description = "Configuration for individual subnets."
  type = map(object({
    address_prefix = string
  }))
  default = {
    frontend = { address_prefix = "10.0.1.0/24" }
    backend  = { address_prefix = "10.0.2.0/24" }
  }
}

variable "location" {
  description = "Azure region for the resources."
  type        = string
  default     = "westeurope"
}
