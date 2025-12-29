variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-azapi-migration"
}

variable "managed_identity_name" {
  description = "The name of the managed identity."
  type        = string
  default     = "uami-azapi-migration"
}

variable "location" {
  description = "Azure region for the resources."
  type        = string
  default     = "westeurope"
}
