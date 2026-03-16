# VNet Hub Peering Example

This deploys a spoke virtual network peered to an inline hub VNet, demonstrating the VNet-to-VNet hub peering scenario.

## Features Tested

- All minimal features (resource groups, Log Analytics, NSGs, route tables, VNets with subnets)
- VNet-to-VNet hub peering (spoke peers to an inline hub VNet)
- Diagnostic settings to Log Analytics workspace

## Inline Dependencies

- `azurerm_resource_group` — hub resource group (separate from spoke)
- `azurerm_virtual_network` — hub VNet (peering target)

## Usage

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

No input variables or `-var-file` flags are required.
