# Minimal Example

This deploys the simplest viable spoke networking configuration using the pattern module.

## Features Tested

- Resource groups (auto-created by the pattern module)
- Log Analytics workspace (auto-created)
- Network Security Groups with security rules
- Route tables with routes
- Virtual networks with subnets (no peering)
- Diagnostic settings to Log Analytics workspace

## Usage

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

No input variables or `-var-file` flags are required — all variables have defaults, and `terraform.tfvars` provides scenario-specific overrides.
