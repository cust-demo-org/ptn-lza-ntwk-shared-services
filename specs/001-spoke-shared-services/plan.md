# Implementation Plan: ALZ Spoke Networking & Shared Services Pattern

**Branch**: `001-spoke-shared-services` | **Date**: 2026-03-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-spoke-shared-services/spec.md`

## Summary

This pattern implements a reusable Terraform root module for provisioning Azure Application Landing Zone (ALZ) spoke networking and shared services. It deploys spoke virtual networks with subnets, NSGs, route tables with user-defined routes, VNet peering to a hub VNet or vWAN hub connection, Private DNS Zone links, managed identities, Key Vaults, and optionally Azure Bastion — all with diagnostic settings routed to a Log Analytics workspace.

The technical approach uses **Azure Verified Modules (AVM)** exclusively — 11 root-level AVM modules plus 2 AVM submodules (`private_dns_virtual_network_link` from `avm-res-network-privatednszone`, `virtual-network-connection` from `avm-ptn-alz-connectivity-virtual-wan`) cover every Azure resource type in scope. Zero custom resource blocks are required. Hub VNet peering is configured per-VNet via the AVM VNet module's built-in `peerings` map. vWAN hub connections are configured via a `vhub_connectivity_definitions` map variable. Both use the implicit map-based toggle pattern (empty map = disabled). All configuration is driven through `terraform.tfvars` with no modifications to `.tf` files required. See [research.md](research.md) for full decision rationale.

## Technical Context

**Language/Version**: Terraform HCL — CLI v1.13.3 (constraint: `>= 1.13, < 2.0`)
**Primary Dependencies**:

| Dependency | Version | Constraint | Purpose |
|---|---|---|---|
| azurerm provider | 4.63.0 | `~> 4.0` | Azure resource management (via AVM modules) |
| azapi provider | 2.8.0 | `~> 2.0` | Transitive dependency via AVM modules |
| random provider | 3.x | `~> 3.0` | Random suffix generation (conditional, via naming module) |
| avm-res-network-privatednszone (submodule) | 0.5.0 | `0.5.0` | DNS zone VNet links (`private_dns_virtual_network_link`) |
| avm-ptn-alz-connectivity-virtual-wan (submodule) | 0.13.5 | `0.13.5` | Virtual Hub VNet connections (`virtual-network-connection`) |
| Azure/naming/azurerm | 0.4.3 | `0.4.3` | CAF-compliant resource naming |
| avm-res-resources-resourcegroup | 0.2.2 | `0.2.2` | Resource groups |
| avm-res-network-virtualnetwork | 0.17.1 | `0.17.1` | VNets, subnets, peering |
| avm-res-network-networksecuritygroup | 0.5.1 | `0.5.1` | NSGs with security rules |
| avm-res-network-routetable | 0.5.0 | `0.5.0` | Route tables with routes |
| avm-res-keyvault-vault | 0.10.2 | `0.10.2` | Key Vaults |
| avm-res-network-bastionhost | 0.9.0 | `0.9.0` | Azure Bastion (optional) |
| avm-res-operationalinsights-workspace | 0.5.1 | `0.5.1` | Log Analytics (auto-create) |
| avm-res-managedidentity-userassignedidentity | 0.4.0 | `0.4.0` | Managed identities |
| avm-res-authorization-roleassignment | 0.3.0 | `0.3.0` | Standalone role assignments |
| avm-res-network-networkwatcher | 0.3.2 | `0.3.2` | Network Watcher flow logs (optional) |

**Storage**: N/A (Terraform state backend — Azure Storage — is pre-provisioned externally)
**Testing**: `terraform fmt -check`, `terraform validate`, `terraform plan`, `terraform-docs` freshness, `tflint`
**Target Platform**: Azure (any Azure region with spoke/hub/vWAN support)
**Project Type**: Terraform root module (infrastructure pattern)
**Performance Goals**: N/A (infrastructure provisioning, not runtime workload)
**Constraints**: All resources via AVM modules or AVM submodules (zero custom resource blocks); no `null_resource`/`local-exec`/scripts; subscription ID via env var not variable; flat root module; snake_case naming; full descriptive names
**Scale/Scope**: Supports multiple VNets, subnets, NSGs, route tables, Key Vaults, managed identities, DNS zone links per deployment; multiple independent instantiations per subscription

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Evidence |
|---|---|---|---|
| I | Terraform-Only Declarative Infrastructure | **PASS** | All infrastructure in HCL only. No scripts, `null_resource`, `local-exec`, `remote-exec`, or provisioners. Terraform version pinned to `>= 1.13, < 2.0`. Provider versions pinned with `~>`. |
| II | Azure Verified Modules Exclusive | **PASS** | 11 AVM root modules + 2 AVM submodules cover ALL resource types in scope. Zero exceptions — no direct `azapi_resource` or `azurerm_*` blocks required. `azapi` is a transitive dependency only. See [research.md §1](research.md). |
| III | Configuration-Driven Reusability | **PASS** | All configuration via `terraform.tfvars`. Variables have explicit types (no `any`), descriptions, and secure defaults. Implicit null-toggle for optional components (`bastion_configuration`, `flowlog_configuration`). Multiple instantiations supported via naming module. See [contracts/variables.md](contracts/variables.md). |
| IV | Security by Default | **PASS** | NSG rules fully user-controlled (FR-008). Key Vault public access disabled by default (FR-017). No public endpoints unless opt-in. Diagnostics on all resources. Sensitive values marked `sensitive = true`. Resource locks via AVM interface. |
| V | Reliability & Determinism | **PASS** | Exact AVM module version pins. No runtime-varying external data. `lifecycle` blocks configurable. Idempotency: consecutive applies with unchanged inputs → zero changes (SC-002). |
| VI | Tooling-Based Documentation | **PASS** | `terraform-docs` generates the entire README from `_header.md`, auto-generated input/output/module docs, and `_footer.md` via `.terraform-docs.yml` (`formatter: "markdown document"`). `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers wrap the full output. CI gate verifies freshness (FR-033–FR-035). |
| VII | Operability & Observability | **PASS** | All resource IDs, names, and connection-relevant attributes exported as outputs. All outputs have descriptions. CAF naming via `Azure/naming/azurerm`. Common `tags` variable. Log Analytics workspace ID exported. See [contracts/outputs.md](contracts/outputs.md). |
| VIII | Extensibility & Composability | **PASS** | Map-based variables allow adding resources without changing `.tf` files. Cross-pattern integration via input/output contracts. No hard-coded subscription IDs, tenant IDs, resource group names, or regions. |

**Gate Result**: **ALL PASS** — No violations. Complexity Tracking section not needed.

## Project Structure

### Documentation (this feature)

```text
specs/001-spoke-shared-services/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output — 12 research decisions
├── data-model.md        # Phase 1 output — 13 entity definitions
├── quickstart.md        # Phase 1 output — deployment guide
├── contracts/
│   ├── variables.md     # Phase 1 output — input variable contract
│   └── outputs.md       # Phase 1 output — output variable contract
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
/
├── main.tf              # All module blocks
├── variables.tf         # All input variable declarations
├── outputs.tf           # All output declarations
├── terraform.tf         # required_version + required_providers
├── terraform.tfvars     # Example/default variable values with rich comments
├── locals.tf            # Computed locals (naming, log analytics workspace ID, resource references)
├── _header.md           # README header content (features, usage, quickstart) — consumed by terraform-docs
├── _footer.md           # README footer content (contributing guide, SpecKit attribution) — consumed by terraform-docs
├── README.md            # Auto-generated by terraform-docs from _header.md + auto-docs + _footer.md
├── .terraform-docs.yml  # terraform-docs configuration (formatter: "markdown document")
├── .tflint.hcl          # tflint configuration
├── examples/
│   ├── minimal/         # Minimal spoke VNet with hub peering (US1)
│   │   └── terraform.tfvars
│   ├── full/            # All features enabled (all user stories)
│   │   └── terraform.tfvars
│   └── vwan/            # vWAN connectivity via vhub_connectivity_definitions (US4)
│       └── terraform.tfvars
└── docs/
    └── decisions/       # ADRs for constitutional exceptions
```

**Structure Decision**: Flat root module — AVM modules provide the sub-module abstraction. Standard Terraform file convention (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tf`) plus `locals.tf` for computed values. A `locals.tf` is added because the pattern requires computed values (naming, log analytics workspace resolution, resource reference lookups) that are better isolated from `main.tf`. Example `.tfvars` files demonstrate the three primary use cases.

## AVM Module Interface Summary

| Module | Key Inputs Used | Built-in Interfaces Used |
|---|---|---|
| resource group | `name`, `location`, `tags` | `lock`, `role_assignments` |
| virtual network | `name`, `location`, `address_space`, `subnets`, `peerings`, `tags` | `diagnostic_settings`, `lock`, `role_assignments` |
| network security group | `name`, `location`, `resource_group_name`, `security_rules`, `tags` | `diagnostic_settings`, `lock`, `role_assignments` |
| route table | `name`, `location`, `resource_group_name`, `routes`, `tags` | `lock`, `role_assignments` |
| key vault | `name`, `location`, `resource_group_name`, `sku_name`, `tags` | `diagnostic_settings`, `lock`, `role_assignments` |
| bastion host | `name`, `location`, `resource_group_name`, `virtual_network_id`, `tags` | `diagnostic_settings`, `lock` |
| log analytics workspace | `name`, `location`, `resource_group_name`, `tags` | `lock` |
| managed identity | `name`, `location`, `resource_group_name`, `tags` | `lock` |
| role assignment (standalone) | `principal_id`, `role_definition_id_or_name`, `scope` | — |
| network watcher | `network_watcher_id`, `network_watcher_name`, `resource_group_name`, `location`, `flow_logs` | `lock`, `role_assignments` |

## AVM Submodules

| Submodule | Parent Module | Version | When Used | Key Inputs |
|---|---|---|---|---|
| `private_dns_virtual_network_link` | `avm-res-network-privatednszone` | 0.5.0 | When `private_dns_zone_links` is non-empty | `parent_id` (DNS zone ID), `virtual_network_id`, `registration_enabled`, `resolution_policy` |
| `virtual-network-connection` | `avm-ptn-alz-connectivity-virtual-wan` | 0.13.5 | When `vhub_connectivity_definitions` is non-empty | `virtual_network_connections` map: `name`, `virtual_hub_id`, `remote_virtual_network_id`, `internet_security_enabled`, `routing` |

## Deployment Order

1. Naming module (no Azure calls — pure computation)
2. Resource groups
3. Log Analytics workspace (auto-create, or skip if external ID provided)
4. Network security groups
5. Route tables
6. Virtual networks (including subnets referencing NSG/RT IDs, and peering config)
7. VNet peering (via VNet module `peerings` map, per-VNet) AND/OR Virtual Hub connection (via `virtual-network-connection` submodule, from `vhub_connectivity_definitions`)
8. Private DNS zone VNet links (via `private_dns_virtual_network_link` submodule)
9. Network Watcher flow logs (optional, via `avm-res-network-networkwatcher`, from `flowlog_configuration`)
10. Managed identities
11. Key Vaults (with RBAC role assignments referencing managed identities)
12. Bastion host (optional, requires `AzureBastionSubnet` from step 6)
13. Standalone role assignments (if any)

## Complexity Tracking

No constitutional violations — section not applicable.
