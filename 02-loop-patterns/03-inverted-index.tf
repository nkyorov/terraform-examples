variable "city_country_map" {
  description = "A simple map of City -> Country"
  type        = map(string)
  default = {
    "London"    = "UK"
    "Manchester"= "UK"
    "Paris"     = "France"
    "Lyon"      = "France"
    "Nice"      = "France"
    "Berlin"    = "Germany"
    "Munich"    = "Germany"
  }
}

# Create an inverted index of Country -> List of Cities
# IMPORTANT: You need the ellipsis at the end of the expression
locals {
  country_city_map = {
    for city, country in var.city_country_map : country => city...
  }
}

output "country_city_map" {
  value = local.country_city_map
}

# Output:
# country_city_map = {
#     France = [
#         "Lyon",
#         "Nice",
#         "Paris",
#       ]
#     Germany = [
#         "Berlin",
#         "Munich",
#       ]
#     UK = [
#         "London",
#         "Manchester",
#       ]
# }

# Another example - group by cost-center
variable "billing_data" {
  type = list(object({
    id          = string
    cost_center = string
    owner       = string
  }))
  default = [
    { id = "virtualMachine-01", cost_center = "AWS-99", owner = "Alice" },
    { id = "kubernetesCluster-01", cost_center = "GCP-42", owner = "Bob" },
    { id = "dashboard-02", cost_center = "AWS-99", owner = "Charlie" },
    { id = "function-03", cost_center = "MS-10", owner = "Dave" },
    { id = "networkAppliance-westeurope", cost_center = "GCP-42", owner = "Eve" },
  ]
}

locals {
  group_by_cost_center = {
    for resource in var.billing_data: resource.cost_center => resource.id...
  }
}

output "group_by_cost_center" {
  value = local.group_by_cost_center
}

# Output:
#  group_by_cost_center = {
#      AWS-99 = [
#          "virtualMachine-01",
#          "dashboard-02",
#        ]
#      GCP-42 = [
#          "kubernetesCluster-01",
#          "networkAppliance-westeurope",
#        ]
#      MS-10  = [
#          "function-03",
#        ]
#    }

# Yet another example
variable "files" {
  type    = list(string)
  default = [
    "config.json",
    "deploy.yaml",
    "readme.txt",
    "policy.json",
    "notes.txt",
    "service.yaml"
  ]
}

locals {
  filter_by_extension = {
    for file in var.files: split(".", file)[1] => file...
  }
}

output "filter_by_extension" {
  value = local.filter_by_extension
}

# Output:
# filter_by_extension  = {
#     json = [
#         "config.json",
#         "policy.json",
#       ]
#     txt  = [
#         "readme.txt",
#         "notes.txt",
#       ]
#     yaml = [
#         "deploy.yaml",
#         "service.yaml",
#       ]
#   }