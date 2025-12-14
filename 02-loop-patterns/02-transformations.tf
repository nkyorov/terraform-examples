# You can use if-statements in for loops.
locals {
  capitals = ["london", "paris", "berlin", "madrid", "rome"]

  capital_title = [for city in local.capitals : title(city) if length(city) > 5]
}

output "capitals" {
  value = local.capital_title
}

# Output: 
# capitals = ["London","Berlin","Madrid"]