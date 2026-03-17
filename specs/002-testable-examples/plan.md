# Implementation Plan: Testable Examples

**Branch**: `002-testable-examples` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-testable-examples/spec.md`

## Summary

Convert the three existing `.tfvars`-only example directories into four self-contained Terraform root modules (`minimal/`, `vnet_hub/`, `vwan_hub/`, `full/`) that can independently `terraform plan` and `terraform apply`. Each example uses a `variables.tf` exposing all pattern module variables (with defaults), a `terraform.tfvars` providing scenario-specific overrides, and a `main.tf` that deploys minimal inline dependencies then calls the pattern module via `source = "../.."`. Provider versions are pinned to exact versions for reproducibility. Additionally, root module variable descriptions are improved to multi-line heredoc format referencing AVM sources, and missing AVM variable pass-through fields are added.

## Technical Context

**Language/Version**: Terraform HCL, CLI >= 1.13 < 2.0
**Primary Dependencies**: azurerm v4.63.0, azapi v2.8.0
**AVM Modules**: 13 modules (resource_group v0.2.2, log_analytics v0.5.1, NSG v0.5.1, route_table v0.5.0, VNet v0.17.1, DNS link submodule v0.5.0, managed_identity v0.4.0, key_vault v0.10.2, role_assignment v0.3.0, vnet_conn v0.13.5, bastion v0.9.0, network_watcher v0.3.2, storage_account v0.6.7)
**Testing**: `terraform fmt -check`, `terraform validate`, `terraform plan`, `terraform apply` (manual)
**Target Platform**: Azure (any region)
**Project Type**: Terraform pattern module with examples
**Constraints**: Examples must plan with zero inputs; exact provider pins; all variables defaulted
**Scale/Scope**: 4 example directories, 17+ root module variables, ~6 files per example
**PE Pattern**: Private endpoints use key-based references (`vnet_key`/`subnet_key`, `private_dns_zone.keys`) resolved internally by the pattern module — callers no longer merge computed IDs in locals
**Bastion Pattern**: Bastion `ip_configuration` uses `network_configuration` sub-object (same shape as PE) for subnet resolution; `virtual_network` uses `object({ resource_id, key })` matching the vHub pattern
**Locals**: `vnet_resource_ids` and `subnet_resource_ids` lookup maps in `locals.tf` centralise VNet/subnet ID resolution — all `module.virtual_network[...]` references go through these locals
**Storage Pattern**: `storage_accounts` variable backed by AVM storage module v0.6.7; flow logs reference storage via nested `storage_account = { resource_id, key }` object; `storage_account_resource_ids` local resolves keys; AVM storage module uses `diagnostic_settings_storage_account` (not `diagnostic_settings`)
**Flow Log Target**: `flow_logs.target_resource_id` replaced with `flow_logs.vnet_key` — flow logs always target module-managed VNets, resolved via `local.vnet_resource_ids[fl.vnet_key]`
**Network Watcher Defaults**: `flowlog_configuration.network_watcher_id`, `network_watcher_name`, `resource_group_name` are `optional(string)` — pattern module computes Azure standard defaults (`NetworkWatcherRG`, `NetworkWatcher_<location>`) via `coalesce`; callers can override for custom Network Watcher setups
**BYO LAW & Traffic Analytics**: `log_analytics_workspace_id` replaced with `byo_log_analytics_workspace = { resource_id, location }` object; `traffic_analytics.workspace_id`, `workspace_region`, `workspace_resource_id` are now optional — pattern module auto-resolves from internal LAW module or BYO data source; `local.default_log_analytics_workspace_resource_id` (renamed for clarity), `local.law_workspace_id`, `local.law_workspace_region` provide resolved values

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Terraform-Only Declarative Infrastructure | ✅ PASS | All example infrastructure is pure HCL. No scripts, provisioners, or local-exec. |
| II | Azure Verified Modules Exclusive | ✅ PASS | Examples call the pattern module (which uses AVM). Inline dependent resources (RGs, hub VNet, vWAN, vHub) use `azurerm_*` only where no AVM module applies to an example's ephemeral testing dependency. |
| III | Configuration-Driven Reusability | ✅ PASS | Examples expose all pattern variables via `variables.tf` with typed, described, defaulted variables. FR-020 improves descriptions. FR-021 adds missing AVM pass-through fields. |
| IV | Security by Default | ✅ PASS | Examples inherit pattern module security defaults. No public endpoints unless explicitly called for by Bastion in the full example. |
| V | Reliability & Determinism | ✅ PASS | Exact provider pins (FR-018). All variables defaulted (FR-006). Idempotency tested by FR-014/SC-003. |
| VI | Tooling-Based Documentation | ✅ PASS | FR-019 adds terraform-docs generated README.md per example with _header.md. FR-020 ensures variable descriptions are meaningful. |
| VII | Operability & Observability | ✅ PASS | Examples inherit pattern module outputs. Each example is self-documenting via terraform-docs README. |
| VIII | Extensibility & Composability | ✅ PASS | New examples follow the established `variables.tf` + `terraform.tfvars` + `main.tf` pattern. FR-021 extends variable types for fuller AVM surface. |

**GATE RESULT: PASS — No violations. Proceed to Phase 0.**

## Project Structure

### Documentation (this feature)

```text
specs/002-testable-examples/
├── plan.md              # This file
├── research.md          # Phase 0 output — AVM audit, provider versions, design decisions
├── data-model.md        # Phase 1 output — variable mapping model per example
├── quickstart.md        # Phase 1 output — developer guide
├── contracts/           # Phase 1 output — example file contracts
│   └── example-layout.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Root module changes (FR-020, FR-021)
variables.tf             # Improved descriptions + added AVM pass-through fields
main.tf                  # Updated module calls to pass new fields

# Example directories (4 total)
examples/
├── minimal/
│   ├── terraform.tf     # Exact provider pins
│   ├── main.tf          # RG + pattern module call
│   ├── variables.tf     # All 17+ pattern variables with minimal defaults
│   ├── terraform.tfvars # Minimal scenario overrides
│   ├── _header.md       # Example description
│   └── README.md        # terraform-docs generated
├── vnet_hub/
│   ├── terraform.tf
│   ├── main.tf          # RG + hub VNet + pattern module call (with peering, depends_on hub VNet)
│   ├── variables.tf
│   ├── terraform.tfvars # Hub peering scenario overrides
│   ├── _header.md
│   └── README.md
├── vwan_hub/            # Renamed from vwan/
│   ├── terraform.tf
│   ├── main.tf          # RG + vWAN + vHub + pattern module call (depends_on vHub)
│   ├── variables.tf
│   ├── terraform.tfvars # vWAN hub connectivity overrides
│   ├── _header.md
│   └── README.md
└── full/
    ├── terraform.tf
    ├── main.tf          # RG + hub VNet + DNS zone + NW + public IP + pattern module call (all features, depends_on inline resources)
    ├── variables.tf
    ├── terraform.tfvars # All-features overrides
    ├── _header.md
    └── README.md
```

**Structure Decision**: Four example directories, each a self-contained root module. The `variables.tf` + `terraform.tfvars` pattern ensures examples test the full variable interface. Root module gets variable description and type improvements (FR-020, FR-021) as prerequisite work.

## Complexity Tracking

No constitution violations require justification. The scope expansion (FR-020, FR-021 for root module changes) is within the spirit of Principle III (Configuration-Driven Reusability) and Principle VI (Tooling-Based Documentation).

## Post-Design Constitution Re-Check

| # | Principle | Status | Design Impact |
|---|-----------|--------|---------------|
| I | Terraform-Only | ✅ PASS | No scripts introduced. All examples are pure HCL. |
| II | AVM Exclusive | ✅ PASS | Inline `azurerm_*` deps in examples are test infrastructure (RG, hub VNet, vWAN), not pattern resources. Pattern module continues to use AVM exclusively. Constitution exemption applies: "Custom resource blocks are permitted ONLY when no AVM module exists for the resource type." For example ephemeral deps, this is acceptable. |
| III | Config-Driven | ✅ PASS | variables.tf + terraform.tfvars pattern provides full configurability. FR-020 improves descriptions. FR-021 adds missing fields. |
| IV | Security Default | ✅ PASS | Examples inherit all pattern module security defaults. No new public endpoints. |
| V | Reliability | ✅ PASS | Exact provider pins. All defaults pass validation. Idempotency tested. |
| VI | Tooling Docs | ✅ PASS | terraform-docs README per example. Heredoc descriptions. |
| VII | Operability | ✅ PASS | Examples self-documenting. Pattern outputs unchanged. |
| VIII | Extensibility | ✅ PASS | New examples follow repeatable pattern. Variable types extended, not restructured. |

**POST-DESIGN GATE: PASS — Ready for task generation (/speckit.tasks).**
