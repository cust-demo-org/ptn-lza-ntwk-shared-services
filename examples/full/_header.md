# Full Example

This deploys every optional feature of the pattern module, exercising the complete interface end-to-end.

## Features Tested

- Resource groups with per-RG lock overrides
- Log Analytics workspace (auto-created)
- Network Security Groups with security rules
- Route tables with routes
- Virtual networks with subnets and VNet-to-VNet hub peering
- Private DNS Zone VNet links
- Managed identities
- Key Vaults with RBAC role assignments and private endpoints (key-based references)
- Standalone role assignments
- Azure Bastion with key-based subnet and VNet references
- Storage accounts (for flow log target)
- Diagnostic settings to Log Analytics workspace

## Inline Dependencies

- `azurerm_resource_group` — hub resource group
- `azurerm_virtual_network` — hub VNet (peering target)
- `azurerm_private_dns_zone` — Private DNS zones for private endpoint resolution

## Usage

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

No input variables or `-var-file` flags are required.
