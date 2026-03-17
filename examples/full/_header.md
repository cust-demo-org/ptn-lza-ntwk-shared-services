# Full Example

This deploys every optional feature of the pattern module, exercising the complete interface end-to-end.
It demonstrates both pattern-managed and BYO (Bring Your Own) Private DNS zones:
blob DNS zone is created by the pattern module via `private_dns_zones`, while
Key Vault DNS zone is created inline and linked via `byo_private_dns_zone_links`.

## Features Tested

- Resource groups with per-RG lock overrides
- Log Analytics workspace (auto-created)
- Network Security Groups with security rules
- Route tables with routes
- Virtual networks with subnets and VNet-to-VNet hub peering
- Private DNS Zones (pattern-managed for blob, BYO for Key Vault)
- BYO Private DNS Zone VNet links with computed zone IDs
- Managed identities
- Key Vaults with RBAC role assignments and private endpoints (key-based references)
- Standalone role assignments with computed scope
- Azure Bastion with key-based subnet/VNet references and auto-created public IP
- Storage accounts (for flow log target)
- Diagnostic settings on all supported resources (LAW, NSGs, VNet, Key Vault, Bastion, Storage Account)
- Storage account sub-resource diagnostic settings (blob, file, queue, table)

## Inline Dependencies

- `azurerm_resource_group` — hub resource group
- `azurerm_virtual_network` — hub VNet (peering target)
- `azurerm_private_dns_zone` — Key Vault DNS zone (BYO, linked to spoke via `byo_private_dns_zone_links`)

## Usage

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

No input variables or `-var-file` flags are required.
