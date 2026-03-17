# vWAN Hub Connectivity Example

This deploys a spoke virtual network connected to a Virtual WAN hub, demonstrating the vWAN hub connectivity scenario as an alternative to VNet-to-VNet peering.

## Features Tested

- All minimal features (resource groups, Log Analytics, NSGs, route tables, VNets with subnets)
- Virtual WAN hub connection (`vhub_connectivity_definitions`)
- Diagnostic settings to Log Analytics workspace

## Inline Dependencies

- `azurerm_resource_group` — connectivity resource group
- `azurerm_virtual_wan` — Virtual WAN instance
- `azurerm_virtual_hub` — Virtual Hub (spoke connects to this)

## Usage

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

No input variables or `-var-file` flags are required.
