# Data Manipulation & Looping Patterns

This repository contains examples and exercises demonstrating various data manipulation techniques in Terraform. The examples range from basic conditional logic in loops to advanced grouping and transformations.


| File Name                                            | Description                                                                                                                        |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| [`01-conditional-loops.tf`](01-conditional-loops.tf) | Filters values in a `for` expression using conditional logic (even numbers example).                                               |
| [`02-transformations.tf`](02-transformations.tf)     | Applies transformations inside `for` expressions with conditional filtering (title-cased cities).                                  |
| [`03-inverted-index.tf`](03-inverted-index.tf)       | Demonstrates grouping and inverted indexes using the ellipsis (`...`) operator, including cost-center and file-extension grouping. |
| [`04-cartesian-product.tf`](04-cartesian-product.tf) | Generates a cartesian product using nested `for` expressions and `flatten()`.                                                      |
