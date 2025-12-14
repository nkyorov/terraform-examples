locals {
  numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  even_numbers = [for n in local.numbers : n if n % 2 == 0]
}

output "even_numbers" {
  value = local.even_numbers
}

# Output:
# even_numbers = [2,4,6,8,10]