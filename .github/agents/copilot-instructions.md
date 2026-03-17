# ptn-lza-ntwk-shared-services Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-09

## Active Technologies
- N/A (Terraform state backend — Azure Storage — is pre-provisioned externally) (001-spoke-shared-services)
- Terraform HCL, CLI >= 1.13 < 2.0 + azurerm v4.63.0, azapi v2.8.0, random v3.8.1, Azure/naming/azurerm v0.4.3 (002-testable-examples)
- HCL (Terraform ~> 1.9) + 14 AVM modules (resource_group v0.2.2, log_analytics_workspace v0.5.1, NSG v0.5.1, route_table v0.5.0, virtual_network v0.17.1, private_dns_zone v0.5.0, managed_identity v0.4.0, key_vault v0.10.2, storage_account v0.6.7, role_assignment v0.3.0, vhub_vnet_connection submodule v0.13.5, bastion_host v0.9.0, network_watcher v0.3.2, private_dns_zone_link submodule v0.5.0) (003-avm-variable-descriptions)
- N/A (documentation-only change) (003-avm-variable-descriptions)

- Terraform HCL — CLI v1.13.3 (constraint: `>= 1.13, < 2.0`) (001-spoke-shared-services)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Terraform HCL — CLI v1.13.3 (constraint: `>= 1.13, < 2.0`)

## Code Style

Terraform HCL — CLI v1.13.3 (constraint: `>= 1.13, < 2.0`): Follow standard conventions

## Recent Changes
- 003-avm-variable-descriptions: Added HCL (Terraform ~> 1.9) + 14 AVM modules (resource_group v0.2.2, log_analytics_workspace v0.5.1, NSG v0.5.1, route_table v0.5.0, virtual_network v0.17.1, private_dns_zone v0.5.0, managed_identity v0.4.0, key_vault v0.10.2, storage_account v0.6.7, role_assignment v0.3.0, vhub_vnet_connection submodule v0.13.5, bastion_host v0.9.0, network_watcher v0.3.2, private_dns_zone_link submodule v0.5.0)
- 002-testable-examples: Added Terraform HCL, CLI >= 1.13 < 2.0 + azurerm v4.63.0, azapi v2.8.0, random v3.8.1, Azure/naming/azurerm v0.4.3
- 001-spoke-shared-services: Added Terraform HCL — CLI v1.13.3 (constraint: `>= 1.13, < 2.0`)


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
