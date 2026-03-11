# Tasks: Testable Examples

**Input**: Design documents from `/specs/002-testable-examples/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not requested in feature specification. No test tasks generated.

**Organization**: Tasks grouped by user story to enable independent implementation and testing of each story. Root module changes (FR-020, FR-021) are foundational prerequisites for example scaffolding per quickstart.md Phase A → B → C ordering.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Logically independent (no data dependencies). Tasks marked [P] within the same file must be serialized but have no ordering constraint relative to each other. Tasks marked [P] across different files can run truly in parallel.
- **[Story]**: Which user story this task belongs to (e.g., US1, US5)
- Exact file paths included in descriptions

---

## Phase 1: Setup

**Purpose**: Repository preparation and directory scaffolding

- [ ] T001 Rename `examples/vwan/` to `examples/vwan_hub/` (preserving existing `terraform.tfvars` content)
- [ ] T002 Create new directory `examples/vnet_hub/`
- [ ] T003 Verify `.gitignore` already ignores `.terraform.lock.hcl` (confirmed — no change needed)

---

## Phase 2: Foundational — Root Module Variable Improvements (FR-020, FR-021)

**Purpose**: Expand root module variable types and descriptions BEFORE example scaffolding. Examples must mirror the post-FR-021 interface, so this phase MUST complete first.

**⚠️ CRITICAL**: No example scaffolding (Phase 3+) can begin until this phase is complete — examples mirror the root module interface.

### FR-021: AVM Variable Pass-Through Audit & Type Expansion

- [ ] T004 Add `lock` field (optional object with `kind`, `name`) to `resource_groups` variable type in `variables.tf`
- [ ] T005 [P] Add `role_assignments` field (optional map of objects) to `resource_groups` variable type in `variables.tf`
- [ ] T006 [P] Add `role_assignments` field to `log_analytics_workspace_configuration` variable type in `variables.tf`
- [ ] T007 [P] Add `role_assignments` field to `network_security_groups` variable type in `variables.tf`
- [ ] T008 [P] Add `role_assignments` field to `managed_identities` variable type in `variables.tf`
- [ ] T009 [P] Add `role_assignments` field to `bastion_configuration` variable type in `variables.tf`
- [ ] T010 [P] Add `role_assignments` field (VNet-level) to `virtual_networks` variable type in `variables.tf`
- [ ] T011 [P] Add `private_endpoints` field to `log_analytics_workspace_configuration` variable type in `variables.tf`
- [ ] T012 Update `module "resource_group"` call in `main.tf` to pass `lock` and `role_assignments` from the expanded variable type
- [ ] T013 [P] Update `module "log_analytics_workspace"` call in `main.tf` to pass `role_assignments` and `private_endpoints` from the expanded variable type
- [ ] T014 [P] Update `module "network_security_group"` call in `main.tf` to pass `role_assignments` from the expanded variable type
- [ ] T015 [P] Update `module "managed_identity"` call in `main.tf` to pass `role_assignments` from the expanded variable type
- [ ] T016 [P] Update `module "bastion_host"` call in `main.tf` to pass `role_assignments` from the expanded variable type
- [ ] T017 [P] Update `module "virtual_network"` call in `main.tf` to pass VNet-level `role_assignments` from the expanded variable type
- [ ] T018 Run `terraform validate` from repository root to confirm no regressions after type expansions

### FR-020: Root Module Variable Description Improvements

- [ ] T019 Convert `resource_groups` variable description to heredoc format with AVM module reference and per-field documentation in `variables.tf`
- [ ] T020 [P] Convert `log_analytics_workspace_configuration` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T021 [P] Convert `network_security_groups` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T022 [P] Convert `route_tables` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T023 [P] Convert `virtual_networks` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T024 [P] Convert `private_dns_zone_links` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T025 [P] Convert `managed_identities` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T026 [P] Convert `key_vaults` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T027 [P] Convert `role_assignments` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T028 [P] Convert `vhub_connectivity_definitions` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T029 [P] Convert `bastion_configuration` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T030 [P] Convert `flowlog_configuration` variable description to heredoc format with AVM module reference in `variables.tf`
- [ ] T031 [P] Convert `location`, `tags`, `use_random_suffix`, `lock`, and `log_analytics_workspace_id` variable descriptions to heredoc format in `variables.tf`
- [ ] T032 Run `terraform fmt -write=true` on root `variables.tf` to ensure formatting compliance
- [ ] T033 Run `terraform validate` to confirm descriptions don't introduce regressions

### SC-007 / SC-008 Verification

- [ ] T033a Review all 17 variable descriptions in root `variables.tf` against SC-007 criteria: each MUST use heredoc format (`<<-EOT ... EOT`) and reference the upstream AVM module name, version, and registry URL
- [ ] T033b [P] Cross-check R4 high and medium priority audit table against implemented type extensions in root `variables.tf` for SC-008 completeness: every field listed in R4 high/medium MUST be present in the variable type definition

**Checkpoint**: Root module variable types expanded (FR-021) and descriptions improved (FR-020). SC-007 and SC-008 verified. Example scaffolding can now begin.

---

## Phase 3: User Story 1 — Run `terraform plan` on any example (Priority: P1) + User Story 3 — Relative source (Priority: P1) 🎯 MVP

**Goal**: All four examples have `terraform.tf`, `main.tf`, `variables.tf` that enable `terraform init && terraform plan` to exit 0 with no variable inputs. Module call uses `source = "../.."`.

**Independent Test**: `cd examples/<name> && terraform init && terraform plan` exits 0 from a clean clone.

**Why combined**: US1 (plan succeeds) and US3 (relative source) are both P1 and are satisfied by the same implementation — creating `main.tf` with `source = "../.."` and `variables.tf` with defaults. They cannot be meaningfully separated.

### minimal/ example (FR-011)

- [ ] T034 [P] [US1] Create `examples/minimal/terraform.tf` with exact provider pins (`azurerm = "4.63.0"`, `azapi = "2.8.0"`, `random = "3.8.1"`) and provider configuration per contracts/example-layout.md
- [ ] T035 [P] [US1] Create `examples/minimal/variables.tf` declaring all 17 pattern module variables with descriptions and defaults appropriate for minimal scenario (RGs, LAW, NSGs, route tables, VNets — no peering; unused features default to `null`/`{}`). Every variable MUST include a `description` attribute per Constitution Principles III and VI.
- [ ] T036 [US1] Create `examples/minimal/main.tf` with naming module (`Azure/naming/azurerm` pinned to `0.4.3`), and pattern module call (`source = "../.."`) passing all variables through. No inline dependencies beyond naming — pattern module creates RGs via `resource_groups` variable
- [ ] T037 [US1] Update `examples/minimal/terraform.tfvars` with scenario-specific overrides for minimal deployment (resource_groups, log_analytics_workspace_configuration, network_security_groups, route_tables, virtual_networks per data-model feature matrix)

### vnet_hub/ example (FR-016)

- [ ] T038 [P] [US1] Create `examples/vnet_hub/terraform.tf` with exact provider pins per contracts/example-layout.md
- [ ] T039 [P] [US1] Create `examples/vnet_hub/variables.tf` declaring all 17 pattern module variables with descriptions and defaults appropriate for VNet hub peering scenario
- [ ] T040 [US1] Create `examples/vnet_hub/main.tf` with naming module, inline `azurerm_resource_group` (hub RG), inline `azurerm_virtual_network` (hub VNet as peering target), and pattern module call (`source = "../.."`) passing all variables. Use locals to merge computed hub VNet ID into `virtual_networks` peering configuration
- [ ] T041 [US1] Create `examples/vnet_hub/terraform.tfvars` with scenario-specific overrides for VNet hub peering deployment (all minimal features + VNet peering to inline hub VNet)

### vwan_hub/ example (FR-013)

- [ ] T042 [P] [US1] Create `examples/vwan_hub/terraform.tf` with exact provider pins per contracts/example-layout.md
- [ ] T043 [P] [US1] Create `examples/vwan_hub/variables.tf` declaring all 17 pattern module variables with descriptions and defaults appropriate for vWAN hub connectivity scenario
- [ ] T044 [US1] Create `examples/vwan_hub/main.tf` with naming module, inline `azurerm_resource_group` (connectivity RG), inline `azurerm_virtual_wan`, inline `azurerm_virtual_hub`, and pattern module call (`source = "../.."`) passing all variables. Use locals to merge computed vHub ID into `vhub_connectivity_definitions`
- [ ] T045 [US1] Update `examples/vwan_hub/terraform.tfvars` (preserved from rename) with scenario-specific overrides for vWAN hub connectivity deployment

### full/ example (FR-012)

- [ ] T046 [P] [US1] Create `examples/full/terraform.tf` with exact provider pins per contracts/example-layout.md
- [ ] T047 [P] [US1] Create `examples/full/variables.tf` declaring all 17 pattern module variables with descriptions and defaults appropriate for full-feature scenario
- [ ] T048 [US1] Create `examples/full/main.tf` with naming module, inline `azurerm_resource_group` (hub RG), inline `azurerm_virtual_network` (hub VNet), inline `azurerm_private_dns_zone`, inline `azurerm_network_watcher`, inline `azurerm_public_ip` (Bastion), inline `azurerm_storage_account` (flow logs), and pattern module call (`source = "../.."`) passing all variables. Use locals to merge computed resource IDs into variable values for peering, DNS links, Bastion, and flow log configuration
- [ ] T049 [US1] Update `examples/full/terraform.tfvars` with scenario-specific overrides exercising ALL pattern features (resource_groups, LAW, NSGs, route_tables, virtual_networks with peering, private_dns_zone_links, managed_identities, key_vaults, role_assignments, bastion_configuration, flowlog_configuration)

### Validation

- [ ] T050 Run `terraform fmt -write=true` recursively across all `examples/` directories
- [ ] T051 Run `terraform init && terraform validate` in `examples/minimal/`
- [ ] T052 [P] Run `terraform init && terraform validate` in `examples/vnet_hub/`
- [ ] T053 [P] Run `terraform init && terraform validate` in `examples/vwan_hub/`
- [ ] T054 [P] Run `terraform init && terraform validate` in `examples/full/`
- [ ] T055 Run `terraform plan` in `examples/minimal/` with no `-var` or `-var-file` flags — verify exit 0
- [ ] T056 [P] Run `terraform plan` in `examples/vnet_hub/` with no flags — verify exit 0
- [ ] T057 [P] Run `terraform plan` in `examples/vwan_hub/` with no flags — verify exit 0
- [ ] T058 [P] Run `terraform plan` in `examples/full/` with no flags — verify exit 0

**Checkpoint**: US1 (plan succeeds in all examples) and US3 (relative source `"../.."`). SC-001 and SC-006 verifiable. This is the **MVP** — examples can be planned from a clean clone.

---

## Phase 4: User Story 5 — No required input variables (Priority: P3)

**Goal**: Verify all `variables.tf` files have defaults and `terraform.tfvars` provides scenario-specific overrides. This user story is inherently satisfied by Phase 3 implementation but warrants explicit verification.

**Independent Test**: Review all `variables.tf` — every variable has a default. Run `terraform plan` with no flags (already verified in Phase 3).

- [ ] T059 [US5] Review `examples/minimal/variables.tf` — confirm all variables have default values and no variable is required
- [ ] T060 [P] [US5] Review `examples/vnet_hub/variables.tf` — confirm all variables have default values
- [ ] T061 [P] [US5] Review `examples/vwan_hub/variables.tf` — confirm all variables have default values
- [ ] T062 [P] [US5] Review `examples/full/variables.tf` — confirm all variables have default values
- [ ] T063 [US5] Review all four `terraform.tfvars` files — confirm they provide scenario-specific overrides (not duplicate defaults)

**Checkpoint**: US5 verified. SC-001 additionally confirmed (no `-var` flags needed).

---

## Phase 5: User Story 4 — Examples deploy only minimal dependencies (Priority: P2)

**Goal**: Each example's `main.tf` deploys the absolute minimum `azurerm_*` resources needed for its scenario. No luxury extras.

**Independent Test**: Review each `main.tf` — count inline resources matches data-model dependency model.

- [ ] T064 [US4] Review `examples/minimal/main.tf` — confirm only naming module + pattern module (no inline `azurerm_*` deps; RGs created by pattern)
- [ ] T065 [P] [US4] Review `examples/vnet_hub/main.tf` — confirm only naming + `azurerm_resource_group` (hub RG) + `azurerm_virtual_network` (hub VNet) + pattern module
- [ ] T066 [P] [US4] Review `examples/vwan_hub/main.tf` — confirm only naming + `azurerm_resource_group` + `azurerm_virtual_wan` + `azurerm_virtual_hub` + pattern module
- [ ] T067 [P] [US4] Review `examples/full/main.tf` — confirm only naming + `azurerm_resource_group` (hub RG) + `azurerm_virtual_network` (hub VNet) + `azurerm_private_dns_zone` + `azurerm_network_watcher` + `azurerm_public_ip` + `azurerm_storage_account` + pattern module
- [ ] T068 [US4] Verify no example uses external AVM modules for inline dependencies (only `azurerm_*` resource blocks + naming module)

**Checkpoint**: US4 verified. Each example deploys bare minimum dependencies per R7 + data-model.

---

## Phase 6: User Story 2 — Run `terraform apply` to deploy a working example (Priority: P2)

**Goal**: Each example deploys, is idempotent, and destroys cleanly.

**Independent Test**: `terraform apply -auto-approve` → verify resources → second apply shows 0 changes → `terraform destroy -auto-approve`.

**Note**: These tasks require an authenticated Azure CLI session and a live Azure subscription.

- [ ] T069 [US2] Run `terraform apply -auto-approve` in `examples/minimal/` — verify successful deployment (SC-002)
- [ ] T070 [US2] Run second `terraform apply` in `examples/minimal/` — verify 0 changes (SC-003, FR-014)
- [ ] T071 [US2] Run `terraform destroy -auto-approve` in `examples/minimal/` — verify clean removal (SC-004, FR-015)
- [ ] T072 [US2] Run `terraform apply -auto-approve` in `examples/vnet_hub/` — verify successful deployment
- [ ] T073 [US2] Run second `terraform apply` in `examples/vnet_hub/` — verify 0 changes
- [ ] T074 [US2] Run `terraform destroy -auto-approve` in `examples/vnet_hub/` — verify clean removal
- [ ] T075 [US2] Run `terraform apply -auto-approve` in `examples/vwan_hub/` — verify successful deployment
- [ ] T076 [US2] Run second `terraform apply` in `examples/vwan_hub/` — verify 0 changes
- [ ] T077 [US2] Run `terraform destroy -auto-approve` in `examples/vwan_hub/` — verify clean removal
- [ ] T078 [US2] Run `terraform apply -auto-approve` in `examples/full/` — verify successful deployment
- [ ] T079 [US2] Run second `terraform apply` in `examples/full/` — verify 0 changes
- [ ] T080 [US2] Run `terraform destroy -auto-approve` in `examples/full/` — verify clean removal

**Checkpoint**: US2 verified. SC-002, SC-003, SC-004 all pass. All examples deploy, are idempotent, and destroy cleanly.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, formatting, and final validation

- [ ] T081 [P] Create `examples/minimal/_header.md` describing the minimal example per contract template (features tested: resource groups, LAW, NSGs, route tables, VNets without peering)
- [ ] T082 [P] Create `examples/vnet_hub/_header.md` describing the VNet hub peering example (features tested: all minimal + VNet-to-VNet hub peering)
- [ ] T083 [P] Create `examples/vwan_hub/_header.md` describing the vWAN hub connectivity example (features tested: all minimal + vhub_connectivity_definitions)
- [ ] T084 [P] Create `examples/full/_header.md` describing the full example (features tested: ALL pattern features including Bastion, Key Vault, managed identities, role assignments, flow logs, DNS links, peering)
- [ ] T085 Generate `examples/minimal/README.md` via `terraform-docs markdown table --output-file README.md --output-mode inject .` in `examples/minimal/`
- [ ] T086 [P] Generate `examples/vnet_hub/README.md` via terraform-docs in `examples/vnet_hub/`
- [ ] T087 [P] Generate `examples/vwan_hub/README.md` via terraform-docs in `examples/vwan_hub/`
- [ ] T088 [P] Generate `examples/full/README.md` via terraform-docs in `examples/full/`
- [ ] T089 Regenerate root module README.md via terraform-docs (reflects updated variable descriptions from FR-020)
- [ ] T090 Run `terraform fmt -check -recursive` from repository root — verify exit 0 (SC-006)
- [ ] T091 Final review: verify SC-005 — all example directories contain `terraform.tf`, `main.tf`, `variables.tf`, `terraform.tfvars`, `_header.md`, and `README.md`

**Checkpoint**: All success criteria (SC-001 through SC-008) verified. Feature complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all example scaffolding
- **US1+US3 (Phase 3)**: Depends on Phase 2 completion (examples mirror post-FR-021 interface)
- **US5 (Phase 4)**: Depends on Phase 3 (reviews variables.tf files created in Phase 3)
- **US4 (Phase 5)**: Depends on Phase 3 (reviews main.tf files created in Phase 3)
- **US2 (Phase 6)**: Depends on Phase 3 (needs working examples to deploy). Requires Azure access.
- **Polish (Phase 7)**: Depends on Phase 3 at minimum. Can start _header.md tasks (T081–T084) in parallel with Phases 4–6.

### User Story Dependencies

- **US1 + US3 (P1)**: Can start after Foundational — No dependencies on other stories
- **US5 (P3)**: Reviews created in Phase 3 — lightweight verification pass
- **US4 (P2)**: Reviews created in Phase 3 — lightweight verification pass
- **US2 (P2)**: Can start after Phase 3 — requires Azure subscription, independent of reviews

### Within Phase 3 (Example Scaffolding)

- `terraform.tf` and `variables.tf` for each example can be created in parallel [P]
- `main.tf` depends on `variables.tf` (must know variable names to pass through)
- `terraform.tfvars` depends on `variables.tf` (must know variable structure for overrides)
- Validation tasks (T050–T058) depend on all files for that example being created
- All four examples can be scaffolded in parallel by different workers

### Within Phase 2 (Root Module Changes)

- FR-021 type expansion tasks (T004–T011) can be done in parallel [P] across variables
- Module call updates (T012–T017) depend on corresponding type expansion completion
- FR-020 description tasks (T019–T031) can run in parallel [P] with FR-021 tasks (different concerns, same file but different sections)
- Validation (T018, T032, T033) must run after all changes to that concern

### Parallel Opportunities

**Phase 2 — parallel batch 1**: T004–T011 (all type expansions) + T019–T031 (all description conversions)
**Phase 2 — parallel batch 2**: T012–T017 (all module call updates)
**Phase 2 — sequential**: T018, T032, T033 (validation)

**Phase 3 — parallel batch per example**: For each example, terraform.tf + variables.tf can run in parallel. Then main.tf, then tfvars.
**Phase 3 — across examples**: All four examples can scaffold in parallel (different directories, no deps).

---

## Parallel Example: Phase 3 (Example Scaffolding)

```text
# All four terraform.tf files in parallel:
T034: examples/minimal/terraform.tf
T038: examples/vnet_hub/terraform.tf
T042: examples/vwan_hub/terraform.tf
T046: examples/full/terraform.tf

# All four variables.tf files in parallel:
T035: examples/minimal/variables.tf
T039: examples/vnet_hub/variables.tf
T043: examples/vwan_hub/variables.tf
T047: examples/full/variables.tf

# Then main.tf files (can parallel across examples):
T036: examples/minimal/main.tf
T040: examples/vnet_hub/main.tf
T044: examples/vwan_hub/main.tf
T048: examples/full/main.tf

# Then tfvars files (can parallel across examples):
T037: examples/minimal/terraform.tfvars
T041: examples/vnet_hub/terraform.tfvars
T045: examples/vwan_hub/terraform.tfvars
T049: examples/full/terraform.tfvars

# Then format + validate all at once:
T050: terraform fmt (all examples)
T051-T054: terraform validate (all in parallel)
T055-T058: terraform plan (all in parallel)
```

---

## Implementation Strategy

### MVP First (Phase 1 + 2 + 3)

1. Complete Phase 1: Setup (rename vwan → vwan_hub, create vnet_hub dir)
2. Complete Phase 2: Root module changes (FR-020 + FR-021)
3. Complete Phase 3: Example scaffolding (US1 + US3)
4. **STOP and VALIDATE**: `terraform plan` exits 0 in all four examples
5. This is the MVP — examples are plannable from a clean clone

### Incremental Delivery

1. Setup + Foundational → Root module improved
2. Phase 3 (US1 + US3) → Plan works → **MVP!**
3. Phase 4 (US5) → Variable defaults verified
4. Phase 5 (US4) → Minimal deps verified
5. Phase 6 (US2) → Apply/idempotency/destroy verified (requires Azure)
6. Phase 7 (Polish) → Documentation + README generation → **Feature complete**

### Single Developer Strategy

Phases are sequential (1 → 2 → 3 → 4/5 → 6 → 7). Within each phase, maximize parallelism by batching file creation across examples.
