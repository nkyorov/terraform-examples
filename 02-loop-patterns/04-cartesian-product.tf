variable "regions" {
  default = ["westeurope", "germany-west-central"]
}

variable "environments" {
  default = ["dev", "prod"]
}

locals {
  cartesian_product = flatten([
    for region in var.regions: [
      for env in var.environments: "${region}-${env}"
    ]
  ])
}

# cartesian_product = ["westeurope-dev","westeurope-prod","germany-west-central-dev","germany-west-central-prod"]
output "cartesian_product" {
  value = local.cartesian_product
}