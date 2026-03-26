# Override files
## What are override files
Terraform normally loads all of the `.tf` and `.tf.json` files within a directory and expects each one to define a distinct set of configuration objects. If two files attempt to define the same object, Terraform returns an error.

Override files are the intentional exception to this rule: you can override specific portions of an existing configuration object in a separate file.

Terraform initially skips these override files when loading configuration, processes them last and tries to merge the override blocks into the existing object.


### Naming
Any file ending in `*_override.tf/` and `*_override.tf.json`, or those named exactly `override.tf` and `override.tf.json` is treated as an override file. 

- `override.tf/override.tf.json` - processed first 
- `*_override.tf/*_override.tf.json` - processed in alphabetical order after `override.tf/override.tf.json`

### How Merging Works


## Use Cases
### Reconfigure state backend for development and testing
### Reconfigure module source URLs to use a local copy
### Reconfigure default variables

# Best practices
- Do not consider this a pattern: **avoid** if you don't really need it
- For local development and testing, add override files to `.gitignore`
- Document everything, as readability takes a huge hit: leave comments in the original configuration files about which overrides applies to each block