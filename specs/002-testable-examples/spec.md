# Feature Specification: Testable Examples

**Feature Branch**: `002-testable-examples`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Improve testability of examples by deploying minimal dependent resources inline following AVM Terraform module example patterns, so that each example can be independently planned and applied."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run `terraform plan` on any example (Priority: P1)

A module contributor or consumer navigates into any example directory (e.g., `examples/minimal/`) and runs `terraform init && terraform plan`. The plan succeeds end-to-end without requiring pre-existing Azure resources, external `.tfvars` overrides, or manual placeholder replacement.

**Why this priority**: This is the fundamental capability being added. Without a successful plan, no other testing or validation is possible. It unblocks CI gates, local validation, and contributor confidence.

**Independent Test**: Run `terraform init && terraform plan` from within the example directory. The command should exit 0 with a non-empty plan showing resources to create.

**Acceptance Scenarios**:

1. **Given** a freshly cloned repository with no prior state, **When** a user runs `terraform init && terraform plan` inside `examples/minimal/`, **Then** the command exits 0 and displays a plan with resources to create.
2. **Given** a freshly cloned repository, **When** a user runs `terraform init && terraform plan` inside `examples/vnet_hub/`, **Then** the command exits 0 and displays a plan covering VNet hub peering resources.
3. **Given** a freshly cloned repository, **When** a user runs `terraform init && terraform plan` inside `examples/vwan_hub/`, **Then** the command exits 0 and displays a plan covering vWAN hub connectivity resources.
4. **Given** a freshly cloned repository, **When** a user runs `terraform init && terraform plan` inside `examples/full/`, **Then** the command exits 0 and displays a plan covering all feature areas.

---

### User Story 2 - Run `terraform apply` to deploy a working example (Priority: P2)

A module contributor runs `terraform apply -auto-approve` in any example directory and all resources deploy successfully to an Azure subscription. The deployment validates the pattern module's behavior end-to-end.

**Why this priority**: Apply proves that the module actually works — plan alone can miss runtime errors (ARM API rejections, resource dependency issues, timing). This is the definitive integration test.

**Independent Test**: Run `terraform apply -auto-approve` in an example directory, verify resources exist in the Azure portal or via `terraform show`, then run `terraform destroy -auto-approve` to clean up.

**Acceptance Scenarios**:

1. **Given** an authenticated Azure CLI session, **When** a user runs `terraform apply -auto-approve` inside `examples/minimal/`, **Then** all resources deploy successfully and `terraform show` reflects the expected resource set.
2. **Given** a successful apply, **When** the user runs `terraform apply` a second time (idempotency check), **Then** no changes are detected ("0 to add, 0 to change, 0 to destroy").
3. **Given** a successful apply, **When** the user runs `terraform destroy -auto-approve`, **Then** all created resources are removed cleanly.

---

### User Story 3 - Module call uses relative source (Priority: P1)

Each example calls the pattern module using `source = "../.."`, ensuring the example always tests the local version of the module rather than a published registry version. This is the AVM convention.

**Why this priority**: Equal to P1 because this is the mechanism that makes examples actually test the module. Without it, examples could pass while the local module is broken.

**Independent Test**: Inspect any example's `main.tf` and confirm `source = "../.."` in the module call.

**Acceptance Scenarios**:

1. **Given** any example directory's `main.tf`, **When** a reviewer inspects the module call, **Then** the source is `"../.."`  (relative to the example directory) and not a registry path.
2. **Given** an example with `source = "../.."`, **When** `terraform init` runs, **Then** it resolves the module from the repository root (two directories up).

---

### User Story 4 - Examples deploy only minimal dependencies (Priority: P2)

Each example deploys the absolute minimum set of supporting Azure resources (e.g., a resource group, a vWAN + vHub for the vWAN example) using plain `azurerm` resources directly — not via other external modules. This keeps examples fast, cheap, understandable, and free of circular dependencies.

**Why this priority**: Deploying heavyweight or unnecessary dependencies makes examples slow, expensive, and brittle. Minimal dependencies follow the AVM convention and keep test costs low.

**Independent Test**: Review each example's `main.tf`. Confirm that only essential resources outside the pattern module are declared, and that they use `azurerm_*` resource blocks (not additional external modules).

**Acceptance Scenarios**:

1. **Given** the `examples/minimal/` example, **When** reviewing dependencies, **Then** only the pattern module call is present — no inline `azurerm_*` resources (resource groups are created by the pattern module via the `resource_groups` variable).
2. **Given** the `examples/vnet_hub/` example, **When** reviewing dependencies, **Then** only a resource group and a hub VNet (to peer with) are created outside the pattern module call.
3. **Given** the `examples/vwan_hub/` example, **When** reviewing dependencies, **Then** only a resource group, vWAN, and vHub are created outside the pattern module call.
4. **Given** any example, **When** counting resources outside the module call, **Then** the count is the bare minimum required for the scenario (no luxury extras).

---

### User Story 5 - No required input variables (Priority: P3)

Examples should run with zero required input variables. All variables declared in `variables.tf` should have default values so that `terraform plan` works without any `-var` or `-var-file` flags. In practice, each example's `terraform.tfvars` provides the scenario-specific values that override defaults.

**Why this priority**: This follows the AVM convention ("No required inputs") and removes friction for contributors and CI pipelines.

**Independent Test**: Run `terraform plan` with no `-var` or `-var-file` arguments. It should succeed.

**Acceptance Scenarios**:

1. **Given** any example directory, **When** running `terraform plan` without any variable inputs, **Then** the plan succeeds (exit 0).
2. **Given** any example's `variables.tf`, **When** reviewed, **Then** all variables have default values.
3. **Given** any example's `terraform.tfvars`, **When** reviewed, **Then** it provides scenario-specific values that override the defaults for that example's deployment.

---

### Edge Cases

- What happens when the module's required variables change? — Examples must be updated in tandem; `terraform plan` in examples serves as the smoke test for interface drift.
- How are dummy resource IDs handled for resources that reference external infrastructure (e.g., hub VNet peering targets)? — Examples deploy dependencies inline (e.g., a hub VNet to peer with). Syntactically valid but non-existent resource IDs will fail plan with provider-level validation errors, so they must be avoided.
- What about the vnet_hub example's hub VNet dependency? — The vnet_hub example deploys its own `azurerm_virtual_network` (hub VNet) inline for the spoke to peer with.
- What about the vwan_hub example's dependency on a vHub? — The vwan_hub example deploys its own `azurerm_virtual_wan` and `azurerm_virtual_hub` resources inline before calling the module.
- What about `flowlog_configuration` which references an external Network Watcher and storage? — The full example deploys an `azurerm_network_watcher` and an `azurerm_storage_account` inline to satisfy the flow log dependencies.
- What about `bastion_hosts` which needs a public IP and subnet? — The full example deploys the AzureBastionSubnet within the VNet and an `azurerm_public_ip` inline.
- What about `byo_private_dns_zone_links` which reference external Private DNS Zones? — The example deploys an `azurerm_private_dns_zone` inline to satisfy the reference.
- Should `.terraform.lock.hcl` files be committed in examples? — No. Lock files are gitignored in example directories. Exact provider version pins (FR-018) provide version reproducibility; lock file hash verification adds cross-platform friction without meaningful benefit.

## Clarifications

### Session 2026-03-10

- Q: Should the full example deploy ALL optional module features (incl. flow logs, peering) with every dependency inline? → A: Yes — full example exercises every optional feature; deploy all dependencies inline.
- Q: What happens to existing `.tfvars` files when `main.tf` is added? → A: Keep them — `.tfvars` files document how users interface with the pattern module; they coexist alongside the new `main.tf`.
- Q: Should the minimal example include VNet peering or omit it? → A: Omit peering — minimal is the simplest viable deployment; peering is covered by the full example.

### Session (Plan Stage)

- Q: How many examples? → A: 4 — `minimal/`, `vnet_hub/` (NEW: demonstrates VNet-to-VNet hub peering), `vwan_hub/` (renamed from `vwan/`), `full/`.
- Q: How should examples pass values to the pattern module? → A: Each example declares all pattern module variables in `variables.tf` (with defaults). `terraform.tfvars` provides scenario-specific overrides. Dependent resources may be hardcoded in `main.tf`.
- Q: Provider version constraints in examples? → A: Exact version pins for repeatability (e.g., `= 4.63.0`), not range constraints.
- Q: Should variable descriptions be improved? → A: Yes (NEW requirement). Root module variable descriptions must use multi-line heredoc format referencing individual AVM module variable descriptions.
- Q: Should all AVM module variables be passed through? → A: Yes (NEW requirement). Audit all 13 AVM modules and ensure every user-configurable variable is exposed in the root module variable types (e.g., `lock` and `role_assignments` missing from `resource_groups`).

### Session (Implementation Stage — Key-Based References)

- Q: Should bastion_hosts use the same key-based `network_configuration` pattern as private endpoints? → A: Yes — `ip_configuration.network_configuration` uses `{ subnet_resource_id, vnet_key, subnet_key }`, identical to the PE shape. This replaces the flat `subnet_id` field.
- Q: Should bastion's `virtual_network_id` become an object? → A: Yes — `virtual_network = object({ resource_id, key })` matches the `vhub_connectivity_definitions.virtual_network` pattern. Provide either a direct `resource_id` or a `key` to resolve from `virtual_networks` map.
- Q: Should `module.virtual_network[...]` references be centralised? → A: Yes — `vnet_resource_ids` and `subnet_resource_ids` lookup maps added to `locals.tf`, following the same pattern as `nsg_resource_ids` and `rt_resource_ids`. All 6 references in `main.tf`/`locals.tf` now go through these locals for cleaner code.

### Session (Implementation Stage — Storage Account Module & Flow Log Storage Reference)

- Q: Should storage accounts be creatable within the pattern module? → A: Yes — `var.storage_accounts` (map of objects) backed by AVM storage module v0.6.7. Secure defaults: `shared_access_key_enabled = false`, `public_network_access_enabled = false`.
- Q: How should flow logs reference a storage account created by the pattern module? → A: Via nested `storage_account = object({ resource_id, key })` — same pattern as bastion `virtual_network` and vHub `virtual_network`. Provide either a direct `resource_id` or a `key` referencing `var.storage_accounts`.
- Q: Should the old flat `storage_account_id` field remain? → A: No — replaced entirely by the nested `storage_account` object for consistency with established key-based patterns.
- Q: What diagnostic settings variable name does the AVM storage module use? → A: `diagnostic_settings_storage_account` (not `diagnostic_settings`). Each sub-resource (blob, file, queue, table) has its own diagnostic settings variable.
- Q: Should the full example create the flow-log storage account inline or via the pattern module? → A: Via the pattern module's `storage_accounts` variable. The `full/` example uses `storage_accounts = { sa_flowlog = { ... } }` in tfvars and references it in flow logs via `storage_account = { key = "sa_flowlog" }`. This exercises the key-based storage reference feature end-to-end.

### Session (Implementation Stage — Flow Log VNet Key Reference)

- Q: Should flow logs accept an arbitrary `target_resource_id` or a key-based reference? → A: Key-based only (`vnet_key`). Flow logs in this pattern module always target VNets created by the module, so `target_resource_id` is replaced with `vnet_key` (resolved via `local.vnet_resource_ids`).
- Q: Does the `full/` example still need `spoke_vnet_id` / `spoke_vnet_name` / `spoke_bastion_subnet_id` locals? → A: No — these were only used to merge `target_resource_id` into flow log config. With `vnet_key`, the pattern module resolves VNet IDs internally. Dead locals removed.

### Session (Implementation Stage — Optional Network Watcher Fields)

- Q: Should `flowlog_configuration.network_watcher_id`, `network_watcher_name`, and `resource_group_name` be required or optional? → A: Optional. Azure auto-creates `NetworkWatcherRG` and `NetworkWatcher_<region>` when VNets are deployed, so the vast majority of deployments use these standard resources. The pattern module now computes defaults via `coalesce`, allowing callers to override for non-standard setups.
- Q: Does the `full/` example still need `nw_rg_name`, `nw_name`, `nw_id` locals? → A: No — the pattern module computes these internally. The locals and their merge overrides were removed from `main.tf`.

### Session (Implementation Stage — BYO LAW & Auto-Resolved Traffic Analytics)

- Q: Should `log_analytics_workspace_id` remain a flat string or become a richer object? → A: Replaced with `byo_log_analytics_workspace = { resource_id, location }` object. The `location` field is needed to resolve `traffic_analytics.workspace_region` without a data source.
- Q: Should `traffic_analytics.workspace_id`, `workspace_region`, `workspace_resource_id` remain required? → A: Made optional. The pattern module auto-resolves them from the Log Analytics workspace. For BYO workspaces, a `data "azurerm_log_analytics_workspace"` retrieves the GUID; for internal workspaces, values come from `module.log_analytics_workspace[0].resource`.
- Q: Does the `full/` example still need `law_rg_name`, `law_name`, `law_resource_id` locals? → A: No — the pattern module resolves all traffic analytics workspace fields internally. Removed the locals and the `workspace_resource_id` merge override.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each example directory MUST be a self-contained Terraform root module with its own `terraform.tf`, `main.tf`, `variables.tf`, and `terraform.tfvars`.
- **FR-002**: Each example MUST declare its own `required_providers` block with version constraints compatible with the root module.
- **FR-003**: Each example MUST include a `provider "azurerm"` configuration block with `features {}`.
- **FR-004**: Each example MUST call the pattern module using `source = "../.."`.
- **FR-005**: Each example MUST deploy all mandatory dependent resources (e.g., resource group) inline using `azurerm_*` resource blocks so that `terraform plan` succeeds without pre-existing infrastructure.
- **FR-006**: Each example MUST have zero required input variables — all variables in `variables.tf` MUST have default values so that `terraform plan` works with no flags. Scenario-specific values are provided via `terraform.tfvars` which overrides the defaults.
- **FR-007**: Each example MUST supply explicit, unique resource names via `terraform.tfvars` to ensure parallel deployments do not collide. The pattern module does not generate names internally.
- **FR-008**: Each example MUST pass `terraform fmt -check` and `terraform validate` cleanly.
- **FR-009**: Each example's `terraform.tfvars` serves as the primary value source for that scenario, providing the concrete values that override `variables.tf` defaults.
- **FR-010**: Each example SHOULD include a `_header.md` file describing what the example demonstrates, following the AVM documentation convention.
- **FR-011**: The `examples/minimal/` example MUST exercise the minimum viable configuration of the pattern module (resource groups, VNet without peering, NSGs, route tables, Log Analytics). Peering and other advanced features are excluded from minimal.
- **FR-012**: The `examples/full/` example MUST exercise all VNet-peering-compatible optional features of the pattern module (Bastion, Key Vault, managed identities, role assignments, flow logs, DNS zone links) by deploying the necessary dependencies inline. vHub connectivity is excluded (covered by the `vwan_hub` example).
- **FR-013**: The `examples/vwan_hub/` example MUST deploy an `azurerm_virtual_wan` and `azurerm_virtual_hub` inline so that the module's vHub connectivity feature can be tested.
- **FR-014**: Each example MUST produce an idempotent deployment — a second `terraform apply` results in zero changes.
- **FR-015**: Each example MUST be destroyable — `terraform destroy` cleanly removes all created resources.
- **FR-016**: The `examples/vnet_hub/` example MUST deploy an `azurerm_virtual_network` (hub VNet) inline so that the module's VNet-to-VNet hub peering feature can be tested.
- **FR-017**: Each example's `variables.tf` MUST declare all pattern module variables (mirroring the root module interface), with defaults appropriate for that scenario. The example's `main.tf` MUST pass these variables through to the `module` call. Dependent resources (resource groups, hub VNet, vWAN, etc.) MAY be hardcoded in `main.tf`.
- **FR-018**: Each example's `terraform.tf` MUST pin provider versions to exact versions (e.g., `= 4.63.0`) for reproducibility, rather than using range constraints.
- **FR-019**: Each example MUST include a `README.md` generated by terraform-docs, consisting of a `_header.md` describing the example followed by the auto-generated documentation. No footer is needed.
- **FR-020** *(root module change, supports US5)*: Root module variable descriptions MUST use multi-line heredoc format and reference the specific AVM module variable descriptions they map to, so consumers can trace each field back to the upstream AVM interface.
- **FR-021** *(root module change, supports US5)*: All user-configurable AVM module variables at high and medium priority (per research R4 audit) MUST be passed through in the root module's variable type definitions. Intentionally excluded fields are documented in R4 with rationale. An audit of all 13 AVM modules must be performed to identify missing fields (e.g., `lock` and `role_assignments` are missing from the `resource_groups` variable type).
- **FR-022** *(learned: type fidelity)*: Pass-through variable types MUST be verified against the actual AVM module source files in `.terraform/modules/`, not inferred from the `azurerm` provider documentation or the AVM registry page. AVM modules may wrap, rename, restructure, or omit provider-level fields (e.g., `queue_properties` is `map(object)` in AVM but the provider uses a flat block; `hour_metrics.enabled` exists at the provider level but is absent in the AVM type).
- **FR-023** *(learned: opt-out defaults)*: When the pattern module auto-fills a field with a resolved default (e.g., `workspace_resource_id` from the pattern's LAW), the variable type MUST include an explicit boolean opt-out flag (e.g., `use_default_log_analytics`) rather than relying on `coalesce` fallback. `coalesce` silently prevents users from setting `null` to opt out of the default.
- **FR-024** *(learned: description clarity)*: Variable descriptions for boolean or opt-in/opt-out fields MUST describe behaviour from the user's perspective — what happens when the value is set or left null — not the internal implementation mechanism. Example: "Set to false to use workspace_resource_id as-is (null = not sent to LAW)" rather than "Set to false to skip coalesce".
- **FR-025** *(learned: documentation sweep)*: After any structural change (feature addition/removal, variable rename, local rename), a full-repo grep sweep MUST be performed to verify that all documentation surfaces (`_header.md`, example READMEs, spec files, quickstart guides, data models) are updated. Header files and example tables are especially prone to drift.
- **FR-026** *(learned: apply-level validation)*: The `examples/full/` example MUST be validated via `terraform apply` (not just `terraform validate`) because type mismatches between the pattern module's variable types and AVM module input types may only surface at apply time when actual values flow through the module call.
- **FR-027** *(learned: intent-signalling locals)*: Local variable names that represent a computed default or fallback value MUST include the role in the name (e.g., `default_log_analytics_workspace_resource_id` not `log_analytics_workspace_resource_id`). This prevents confusion about whether the local is the final resolved value or a fallback.

### Key Entities

- **Example Directory**: A subdirectory under `examples/` that is a self-contained Terraform root module (has `terraform.tf`, `main.tf`, `variables.tf`, `terraform.tfvars`, and calls the pattern module via `source = "../.."`).
- **Dependent Resource**: An `azurerm_*` resource declared inside the example's `main.tf` that exists solely to satisfy a prerequisite of the pattern module (e.g., `azurerm_resource_group`, `azurerm_virtual_wan`, `azurerm_virtual_network` for hub).
- **Pattern Module Call**: The `module "..." { source = "../.." }` block that invokes the pattern module under test, passing through variables from the example's `variables.tf`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `terraform init && terraform plan` exits 0 in every example directory when run from a clean clone with no pre-existing state or variable inputs.
- **SC-002**: `terraform apply -auto-approve` succeeds in every example directory against a live Azure subscription.
- **SC-003**: A second consecutive `terraform apply` in each example reports zero changes (idempotency).
- **SC-004**: `terraform destroy -auto-approve` succeeds and removes all resources created by each example.
- **SC-005**: Every example directory has at minimum `terraform.tf`, `main.tf`, `variables.tf`, `terraform.tfvars`, `_header.md`, and `README.md`. No example directory contains only a `terraform.tfvars`.
- **SC-006**: All examples pass `terraform fmt -check` and `terraform validate` with zero errors.
- **SC-007**: All root module variable descriptions use multi-line heredoc format (`<<-EOT ... EOT`) and reference the upstream AVM module and variable they map to.
- **SC-008**: All high and medium priority AVM module variables identified in the R4 audit are exposed in the root module's variable type definitions.
- **SC-009**: Every example's module call uses `source = "../.."` (relative to the example directory, resolving to the repository root module). No registry paths are used.

## Assumptions

- The repository has been merged to `main` with the `001-spoke-shared-services` feature complete (all 15 root module variables, 13 AVM module blocks).
- Provider version constraints in examples will use exact pins (e.g., `= 4.63.0`, `= 2.8.0`, `= 3.8.1`) for reproducibility, matching the latest versions at time of authoring.
- Resource naming is the responsibility of pattern consumers; examples supply explicit names via `terraform.tfvars`.
- For features requiring external resources that are impractical to deploy inline (e.g., existing Private DNS Zones for the `byo_private_dns_zone_links` variable), examples will deploy a minimal `azurerm_private_dns_zone` inline.
- Examples are not CI-automated in this feature — CI integration would be a follow-up concern. This feature focuses on making examples locally runnable.
- The `vhub_connectivity_definitions` feature requires a vWAN + vHub, which are relatively expensive and slow to deploy. The vwan_hub example accepts this cost as a trade-off for testability.
- Each example's `variables.tf` mirrors the root module's variable interface (all 17 variables, some with expanded type definitions per FR-021, all with defaults). `terraform.tfvars` provides the scenario-specific overrides. This enables both `terraform plan` with no flags (defaults) and realistic deployments (via tfvars).

## Scope Boundaries

**In scope**:

- Converting `examples/minimal/`, `examples/full/`, and `examples/vwan/` (renamed to `examples/vwan_hub/`) from `.tfvars`-only directories into self-contained Terraform root modules.
- Adding a new `examples/vnet_hub/` directory demonstrating VNet-to-VNet hub peering.
- Adding `terraform.tf`, `main.tf`, `variables.tf`, `terraform.tfvars`, `_header.md`, and `README.md` to each example.
- Each example's `variables.tf` declares all pattern module variables with defaults; `terraform.tfvars` provides scenario-specific overrides.
- Deploying minimal dependent resources inline in each example.
- Exact provider version pins in examples for reproducibility.
- terraform-docs generated `README.md` per example.
- Root module variable description improvements (multi-line heredoc, AVM references) — FR-020.
- Root module AVM variable pass-through audit and additions — FR-021.

**Out of scope**:

- CI/CD pipeline integration for automated example testing.
- Adding new example scenarios beyond the four defined (minimal, vnet_hub, vwan_hub, full).
- Modifying the root pattern module's core logic or AVM module versions (variable type extensions for FR-021 are in scope).
- Automated end-to-end test frameworks (e.g., Terratest, tftest).
- Example `outputs.tf` files re-exporting pattern module outputs — may be added in a follow-up.
