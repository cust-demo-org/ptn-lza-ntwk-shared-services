# Tasks: AVM-Style Variable Descriptions

**Input**: Design documents from `/specs/003-avm-variable-descriptions/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: No test tasks included — not requested in spec. Validation via `terraform validate` and `terraform-docs` is included as checkpoint tasks.

**Organization**: All 4 user stories are cross-cutting concerns applied to the same file (`variables.tf`). US1 (Self-Service) and US2 (AVM Consistency) are inseparable P1 work — every variable rewrite satisfies both simultaneously. US3 (Pattern Context) and US4 (terraform-docs Rendering) are P2 audit/validation passes after all descriptions are written. Tasks are organized by variable complexity within primary story phases.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US3, US4)
- Exact file paths included in descriptions

## Path Conventions

- All variable rewrites target ONE file: `variables.tf` at repository root
- AVM sources: `examples/full/.terraform/modules/<module>/variables.tf`
- Design documents: `specs/003-avm-variable-descriptions/`
- Contracts: `specs/003-avm-variable-descriptions/contracts/description-style.md`

---

## Phase 1: Setup

**Purpose**: Verify prerequisites and environment readiness

- [x] T001 Verify branch `003-avm-variable-descriptions` is checked out and working tree is clean in repository root
- [x] T002 Run `terraform init` in `examples/full/` to populate `.terraform/modules/` with all 14 AVM module sources
- [x] T003 Verify `terraform-docs` executable is available at `C:\Users\minheinaung\AppData\Local\Microsoft\WinGet\Packages\Terraform-docs.Terraform-docs_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform-docs.exe`

---

## Phase 2: Foundational (Template Establishment)

**Purpose**: Establish the description rewrite template using the simplest complex variable (`resource_groups`), confirming the pattern works end-to-end before applying to all other variables

**⚠️ CRITICAL**: The `resource_groups` rewrite serves as the reference for all subsequent variables. Must pass validation before proceeding.

- [x] T004 Rewrite `resource_groups` description (starting ~L23) in `variables.tf`: read AVM source from `examples/full/.terraform/modules/resource_group/variables.tf`, then rewrite following contracts/description-style.md §1 (map(object) top-level structure with "deliberately arbitrary" statement), §2 (attribute bullet format with Required/Optional markers), §3a (lock block template), §3b (role_assignments standard 9-field template), §4 (resource_group_key cross-reference note — N/A for resource_groups itself but establish tags pattern note); include all ~5 leaf attrs; remove any existing `Uses:` / `See:` provenance lines per FR-001
- [x] T005 Validate the `resource_groups` rewrite: run `terraform validate` on root module and all 4 example directories (`examples/minimal`, `examples/vnet_hub`, `examples/vwan_hub`, `examples/full`); also run `terraform-docs .` on root module and spot-check rendered output for `resource_groups` to catch rendering issues early (FR-011)

**Checkpoint**: Template pattern validated — `resource_groups` description is the reference for all subsequent rewrites.

---

## Phase 3: US1/US2 — Trivial & Low Complexity Variables (P1)

**Goal**: Rewrite 6 simple variables to establish broad coverage quickly. Each description becomes self-contained for tfvars authoring (US1) using AVM-consistent formatting (US2).

**Independent Test**: A user can populate tfvars for these variables using only the description. `terraform validate` passes on root + 4 examples.

### Implementation

- [x] T006 [US1] Rewrite `location` (starting ~L1) description in `variables.tf` — light polish only per FR-018: read current description, backtick-wrap inline values (e.g., `var.location`), ensure description ends with a period, verify sentence is meaningful to a consumer per constitution VI; add `> **Pattern note:** Defaults to the value of \`var.location\`.` if pattern defaulting applies; do NOT convert to bullet-list format
- [x] T007 [US1] Rewrite `tags` (starting ~L10) description in `variables.tf` — light polish only per FR-018: read current description, backtick-wrap inline values, ensure description ends with a period, note the type is `map(string)`; add `> **Pattern note:** Merged with \`var.tags\`.` to document the merge behavior; do NOT convert to bullet-list format
- [x] T008 [US1] Rewrite `byo_log_analytics_workspace` (starting ~L58) description in `variables.tf`: this is a pattern-specific variable (no direct AVM source), follow contracts §1 (single object structure) and §2 (attribute bullets); ~2 attrs (`resource_id`, `workspace_id`); add pattern note explaining this is for bringing an existing LAW
- [x] T009 [US1] Rewrite `byo_private_dns_zone_links` (starting ~L562) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/` private_dns_zone link submodule, follow contracts §1 (map(object) with "deliberately arbitrary"), §2, §4 (cross-reference keys: `virtual_network_key` references `virtual_networks` variable); ~5 attrs
- [x] T010 [US1] Rewrite `route_tables` (starting ~L287) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/route_table/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments standard 9-field), §4 (`resource_group_key` references `resource_groups`); ~12 attrs including `routes` nested map(object) with its own "deliberately arbitrary" statement
- [x] T011 [US1] Rewrite standalone `role_assignments` (starting ~L821) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/role_assignment/variables.tf`, follow contracts §3f (standalone variant — NOT §3b); ~6 attrs with `scope`, `managed_identity_key`; document mutual exclusivity of `principal_id` vs `managed_identity_key` per FR-017 (inline on each attribute + `> Note:` callout); WARNING: this uses `avm-res-authorization-roleassignment` and has different fields than nested role_assignments blocks
- [x] T012 [US1] Validate Phase 3 rewrites: run `terraform validate` on root module and all 4 example directories; also run `terraform-docs .` on root module and spot-check rendered output for Phase 3 variables to catch rendering issues early (FR-011)

**Checkpoint**: 8 of 17 variables complete (including `resource_groups` from Phase 2). All trivial/low-complexity variables validated.

---

## Phase 4: US1/US2 — Medium Complexity Variables (P1)

**Goal**: Rewrite 6 medium-complexity variables with standard interface blocks (lock, role_assignments, diagnostic_settings) and cross-reference keys. Completes the core of the variable inventory.

**Independent Test**: Each description documents all nested attributes with `(Required)`/`(Optional)` markers. Cross-reference keys state the correct target variable. `terraform validate` passes.

### Implementation

- [x] T013 [US1] Rewrite `network_security_groups` (starting ~L211) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/network_security_group/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings — fix "Key Vault" copy-paste bug per research.md §6), §4 (`resource_group_key`); ~18 attrs including `security_rules` nested map(object) with protocol, source/destination port ranges, access, direction, priority
- [x] T014 [US1] Rewrite `private_dns_zones` (starting ~L511) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/private_dns_zone/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §4 (`resource_group_key`, `virtual_network_key` in `virtual_network_links` sub-object references `virtual_networks`); ~15 attrs
- [x] T015 [US1] Rewrite `managed_identities` (starting ~L591) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/managed_identity/variables.tf`, follow contracts §1, §2, §3a (lock), §3c (role_assignments MANAGED IDENTITY VARIANT — uses `scope` not `principal_id`, only 6 fields; fix "container app environment" copy-paste bug per research.md §6), §4 (`resource_group_key`); ~12 attrs including `federated_identity_credentials`
- [x] T016 [US1] Rewrite `vhub_connectivity_definitions` (starting ~L851) description in `variables.tf`: read AVM source from the vhub_vnet_connection submodule under `examples/full/.terraform/modules/` (exact path may be nested — run `Get-ChildItem -Recurse -Filter variables.tf` under `.terraform/modules/` during T002 to locate it), follow contracts §1, §2, §4 (`vnet_key` references `virtual_networks`); ~10 attrs including routing config (`associated_route_table`, `propagated_route_tables`)
- [x] T017 [US1] Rewrite `bastion_hosts` (starting ~L903) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/bastion_host/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings), §4 (`resource_group_key`, `subnet_key` in `ip_configuration` references `virtual_networks[].subnets`); ~20 attrs including `ip_configuration` sub-object and `sku`
- [x] T018 [US1] Rewrite `flowlog_configuration` (starting ~L1443) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/network_watcher/variables.tf`, follow contracts §1 (single object wrapping `flow_logs` map(object)), §2, §4 (`vnet_key` in flow_logs references `virtual_networks`); ~15 attrs including `retention_policy`, `storage_account` (nested object with `key` field — this is NOT a cross-reference key, it is a nested field named `key` inside a `storage_account` object), `traffic_analytics`; fix "A map of role flow logs" typo per research.md §6; add pattern note that network_watcher is auto-created
- [x] T019 [US1] Validate Phase 4 rewrites: run `terraform validate` on root module and all 4 example directories

**Checkpoint**: 14 of 17 variables complete. All medium-complexity variables validated.

---

## Phase 5: US1/US2 — High & Very High Complexity Variables (P1)

**Goal**: Rewrite the 4 most complex variables with the deepest nesting and largest attribute counts. Each variable gets its own validation step due to size and risk.

**Independent Test**: Every leaf attribute is individually documented — no attribute left undocumented. Storage accounts merges descriptions from all 6 AVM source files. `terraform validate` passes after each variable.

### Implementation

- [x] T020 [US1] Rewrite `log_analytics_workspace_configuration` (starting ~L71) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/log_analytics_workspace/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings), §3e (private_endpoints with full ip_configurations sub-block), §5 (`use_default_log_analytics` pattern-specific boolean); ~45 attrs across `identity`, `customer_managed_key`, `data_exports`, `tables`, `linked_storage_accounts`, `diagnostic_settings`, `private_endpoints`, `lock`, `role_assignments`
- [x] T021 [US1] Validate `log_analytics_workspace_configuration` rewrite: run `terraform validate` on root module and all 4 example directories
- [x] T022 [US1] Rewrite `key_vaults` (starting ~L634) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/key_vault/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings), §3e (private_endpoints), §4 (`resource_group_key`, `subnet_key` in private_endpoints references `virtual_networks[].subnets`, `managed_identity_key` references `managed_identities`); ~50 attrs across `contacts`, `keys` (with `key_opts`, `rotation_policy` sub-objects), `secrets`, `network_acls`, `private_endpoints`, `diagnostic_settings`, `lock`, `role_assignments`
- [x] T023 [US1] Validate `key_vaults` rewrite: run `terraform validate` on root module and all 4 example directories
- [x] T024 [US1] Rewrite `virtual_networks` (starting ~L333) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/virtual_network/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings — fix "Key Vault" copy-paste bug per research.md §6), §4 (`resource_group_key`, `network_security_group_key` in subnets references `network_security_groups`, `route_table_key` in subnets references `route_tables`); ~55 attrs — document ALL ~30 peering attributes and ALL ~15 subnet attributes individually per clarification Q3; `subnets` and `peerings` are both nested map(object) with their own "deliberately arbitrary" statements
- [x] T025 [US1] Validate `virtual_networks` rewrite: run `terraform validate` on root module and all 4 example directories
- [x] T026 [US1] Rewrite `storage_accounts` (starting ~L1000) description in `variables.tf`: read AVM sources from ALL 6 files per research.md §7 — `examples/full/.terraform/modules/storage_account/variables.tf`, `variables.storageaccount.tf`, `variables.diagnostics.tf`, `variables.container.tf`, `variables.queue.tf`, `variables.share.tf`; follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings for MAIN resource + `diagnostic_settings_blob`, `diagnostic_settings_file`, `diagnostic_settings_queue`, `diagnostic_settings_table` sub-diagnostics all reusing §3d template), §3e (private_endpoints), §4 (`resource_group_key`, `subnet_key`, `managed_identity_key`); ~80+ attrs across `blob_properties` (cors_rule, container_delete_retention_policy, delete_retention_policy, restore_policy), `share_properties` (cors_rule, retention_policy, smb), `queue_properties` (cors_rule, hour_metrics, logging, minute_metrics), `network_rules`, `containers`, `managed_identities`, `private_endpoints`, `diagnostic_settings`, `lock`, `role_assignments`
- [x] T027 [US1] Validate `storage_accounts` rewrite: run `terraform validate` on root module and all 4 example directories

**Checkpoint**: All 17 variables rewritten (SC-001). All leaf attributes documented (SC-002). `map(object)` variables have "deliberately arbitrary" statement (SC-006).

---

## Phase 6: US3 — Pattern-Specific Context Audit (P2)

**Goal**: Verify all pattern-specific behaviors are documented with `> **Pattern note:**` callouts, clearly separated from AVM-sourced text per FR-009.

**Independent Test**: Every pattern-specific note is identifiable by reading the description alone — not mixed into AVM-sourced text without attribution.

### Implementation

- [x] T028 [US3] Audit all cross-reference key descriptions in `variables.tf`: verify each of the 7 key attributes (`resource_group_key`, `vnet_key`, `virtual_network_key`, `subnet_key`, `network_security_group_key`, `route_table_key`, `managed_identity_key`) states its target variable per data-model.md § Cross-Reference Key Attributes and contracts §4
- [x] T029 [US3] Audit all `use_default_log_analytics` occurrences in `variables.tf`: verify the pattern-specific boolean is documented in every `diagnostic_settings` block with default value (`true`), true-behavior (auto-sets `workspace_resource_id`), and false-behavior per contracts §5
- [x] T030 [US3] Audit pattern-specific defaulting notes in `variables.tf`: verify `location` mentions `var.location` default, nested `tags` attributes mention merge with `var.tags`, and `flowlog_configuration` mentions network_watcher auto-creation per research.md §5 pattern note table
- [x] T031 [US3] Verify all pattern notes use `> **Pattern note:**` callout format and appear AFTER AVM-sourced attribute descriptions (not interleaved) per contracts §4 and FR-009
- [x] T032 [US3] Audit all `validation` blocks in `variables.tf`: scan for every `validation { ... }` block and verify the corresponding description mentions the constraint so users understand the rule without reading HCL per FR-017 (not limited to mutual exclusivity — includes any validation constraint)

**Checkpoint**: All pattern-specific context documented and correctly separated (US3 acceptance criteria met).

---

## Phase 7: US4 — terraform-docs Rendering Validation (P2)

**Goal**: Ensure all rewritten descriptions render cleanly in terraform-docs Markdown output with no artifacts.

**Independent Test**: Run `terraform-docs .` and inspect all 17 variable descriptions — no broken bullets, orphaned text, or mangled backticks.

### Implementation

- [x] T033 [US4] Run `terraform-docs .` on root module and inspect rendered output for all 17 variable descriptions: check for proper bullet nesting, backtick formatting, no orphaned text, no broken indentation per contracts §7 rendering rules
- [x] T034 [US4] Fix any rendering artifacts found in `variables.tf` descriptions (broken indentation, escaped backtick issues in heredocs, orphaned bullets, missing blank lines before `> Note:` callouts)
- [x] T035 [US4] Regenerate all READMEs per quickstart Step 5: run `terraform-docs .` on root module and all 4 example directories (`examples/minimal`, `examples/vnet_hub`, `examples/vwan_hub`, `examples/full`)
- [x] T036 [US4] Final `terraform validate` on root module and all 4 example directories — confirms SC-005

**Checkpoint**: terraform-docs output clean for all 17 variables (SC-004). All configs validate (SC-005).

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final verification against all success criteria

- [x] T037 Verify SC-001 and SC-002: grep `variables.tf` for remaining `Uses:` or `See:` or `See AVM module` lines — all should return 0 matches (confirms all variables rewritten and no attributes deferred to external references)
- [x] T038 Verify SC-006: grep `variables.tf` for "deliberately arbitrary" and count matches — must match the number of `map(object)` variables and nested `map(object)` attributes listed in data-model.md §3 (Deliberately Arbitrary Map Keys Statement)
- [x] T039 Run quickstart.md Step 6 final verification checklist: SC-001 (17 variables), SC-002 (100% attrs), SC-003 (self-sufficient README), SC-004 (clean rendering), SC-005 (terraform validate pass), SC-006 (deliberately arbitrary statements)

---

## Phase 9: FR-026 — Universalise `managed_identity_key` Across All Role Assignments

**Goal**: Extend `managed_identity_key` support from only `key_vaults` and standalone `role_assignments` to ALL resources with `role_assignments` blocks.

**Independent Test**: Every resource with `role_assignments` (except `resource_groups` due to circular dependency) accepts either `principal_id` or `managed_identity_key`, and `terraform validate` passes.

### Implementation

- [x] T040 [FR-026] Audit all `role_assignments` blocks in `variables.tf`: identify all 21 type definitions, 15 `main.tf` resolution points, and categorise as top-level (9) vs sub-resource (12)
- [x] T041 [FR-026] Update type definitions in root `variables.tf`: change `principal_id = string` to `principal_id = optional(string)` and add `managed_identity_key = optional(string)` in all 19 blocks (excluding `resource_groups` and `managed_identities` which use `scope` not `principal_id`)
- [x] T042 [FR-026] Update `main.tf` resolution: add ternary `ra.managed_identity_key != null ? local.managed_identity_principal_ids[ra.managed_identity_key] : ra.principal_id` to all 9 top-level module `role_assignments`, 3 private endpoint blocks, and 7 sub-resource blocks (subnets, keys, secrets, queues, tables, shares, containers)
- [x] T043 [FR-026] Revert `resource_groups` — discovered circular dependency: `module.resource_group` → `local.managed_identity_principal_ids` → `module.managed_identity` → `local.resource_group_names` → `module.resource_group`. Reverted type to `principal_id = string`, removed `managed_identity_key` field, reverted `main.tf` to pass-through. Added `> **Pattern note:**` explaining limitation.
- [x] T044 [FR-026] Add XOR validation blocks to 8 top-level variables: `log_analytics_workspace_configuration`, `network_security_groups`, `route_tables`, `virtual_networks`, `private_dns_zones`, `bastion_hosts`, `storage_accounts`, `flowlog_configuration` (with `var.flowlog_configuration == null ? true :` null guard)
- [x] T045 [FR-026] Update all 14 role_assignments description blocks: change `principal_id` from `(Required)` to `(Optional)` with "Mutually exclusive with `managed_identity_key`" inline, add `managed_identity_key` description line. Sub-resource blocks (5) get description-only; top-level blocks (9) get description + validation.
- [x] T046 [FR-026] Update example `variables.tf` files: replicate type changes (`principal_id = optional(string)` + `managed_identity_key = optional(string)`) in all 4 example directories. Revert `resource_groups` to `principal_id = string` in examples.
- [x] T047 [FR-026] Run `terraform validate` on root module and all 4 examples — all pass
- [x] T048 [FR-026] Regenerate READMEs via `terraform-docs .` on root and all 4 examples (using `.terraform-docs.yml` config)
- [x] T049 [FR-026] Update spec.md: add FR-026, reconcile FR-010/Out-of-Scope/Assumptions exceptions, add lessons learned L23–L25

**Checkpoint**: `managed_identity_key` supported in all role_assignments blocks except `resource_groups` (documented limitation). All configs validate. READMEs regenerated.

---

## Phase 10: FR-027 — Global `enable_telemetry` Variable

**Goal**: Add a global `enable_telemetry` variable (default `true`) and wire it through to all 14 AVM module calls.

**Independent Test**: Setting `enable_telemetry = false` in tfvars disables telemetry for all AVM modules. `terraform validate` passes on root and all examples.

### Implementation

- [x] T050 [FR-027] Audit all 14 AVM modules for `enable_telemetry` variable support — 12 of 14 confirmed (resource_group, log_analytics_workspace, network_security_group, route_table, virtual_network, private_dns_zone, managed_identity, key_vault, storage_account, role_assignment, bastion_host, network_watcher). 2 submodules (`private_dns_zone_link` submodule `//modules/private_dns_virtual_network_link`, `vhub_vnet_connection` submodule `//modules/virtual-network-connection`) do NOT expose `enable_telemetry`.
- [x] T051 [FR-027] Add `variable "enable_telemetry"` to root `variables.tf` (type `bool`, default `true`, placed between `location` and `tags`)
- [x] T052 [FR-027] Wire `enable_telemetry = var.enable_telemetry` to 12 module calls in `main.tf` (excluding `private_dns_zone_link` and `vhub_vnet_connection` submodules). Replace hardcoded `enable_telemetry = false` in storage_account.
- [x] T053 [FR-027] Add `enable_telemetry` variable to all 4 example `variables.tf` files and wire through `main.tf` `module "pattern"` call
- [x] T054 [FR-027] Run `terraform validate` on root and all 4 examples
- [x] T055 [FR-027] Regenerate READMEs via `terraform-docs .` on root and all 4 examples
- [x] T056 [FR-027] Update spec.md: add FR-027, update plan.md and tasks.md

**Checkpoint**: `enable_telemetry` variable available globally. All 14 AVM modules receive it. All configs validate. READMEs regenerated.

---

## Phase 11: FR-028 — Per-Resource `name_random_suffix_configuration`

**Goal**: Replace the global `random_suffix_length` variable with per-resource `name_random_suffix_configuration` on `key_vaults` and `storage_accounts`, giving users granular control over random name suffixes for globally unique resources.

**Independent Test**: Setting `name_random_suffix_configuration = { length = 4 }` on a storage account or `{ length = 4, append_with_hyphen = true }` on a key vault appends random characters. Omitting it uses the name as-is. `terraform validate` passes on root and all examples.

### Implementation

- [x] T057 [FR-028] Remove global `random_suffix_length` variable from root `variables.tf`
- [x] T058 [FR-028] Remove `random_string.name_suffix` resource from `main.tf` and `local.name_suffix` from `locals.tf`
- [x] T059 [FR-028] Add `name_random_suffix_configuration` optional object to `key_vaults` type definition (root + 4 examples) with `length` (number) and `append_with_hyphen` (optional bool, default `true`)
- [x] T060 [FR-028] Add `name_random_suffix_configuration` optional object to `storage_accounts` type definition (root + full example) with `length` (number)
- [x] T061 [FR-028] Add per-resource `random_string.key_vault_suffix` and `random_string.storage_account_suffix` resources to `main.tf`
- [x] T062 [FR-028] Update key_vault and storage_account module `name` arguments to use per-resource suffix when configured
- [x] T063 [FR-028] Update full example `terraform.tfvars` to demonstrate `name_random_suffix_configuration` on both key vault and storage account
- [x] T064 [FR-028] Update descriptions for both variables with 24-character max name length warning
- [x] T065 [FR-028] Run `terraform validate` on root and all 4 examples
- [x] T066 [FR-028] Regenerate READMEs via `terraform-docs .` on root and all 4 examples
- [x] T067 [FR-028] Update spec.md: add FR-028, update plan.md and tasks.md

**Checkpoint**: Per-resource random suffix config available on key_vaults and storage_accounts. Global `random_suffix_length` removed. All configs validate. READMEs regenerated.

---

## Phase 12: FR-029 — `assign_to_caller` for All Role Assignments

**Goal**: Add `assign_to_caller = optional(bool, false)` to every `role_assignments` block across all variables, enabling users to automatically assign roles to the identity running Terraform via `data.azurerm_client_config.current.object_id`. Mutually exclusive with `principal_id` and `managed_identity_key`.

**Independent Test**: Setting `assign_to_caller = true` on a key vault role assignment resolves to the caller's object ID. Setting both `assign_to_caller = true` and `principal_id` triggers validation error. `terraform validate` passes on root and all examples.

### Implementation

- [x] T068 [FR-029] Add `assign_to_caller = optional(bool, false)` to all 20 standard `role_assignments` blocks in root `variables.tf` (blocks with `managed_identity_key`)
- [x] T069 [FR-029] Update `resource_groups` variable: change `principal_id` from `string` to `optional(string)`, add `assign_to_caller = optional(bool, false)` (no `managed_identity_key` — circular dependency)
- [x] T070 [FR-029] Update all 11 validation blocks to 3-way XOR: `((ra.principal_id != null ? 1 : 0) + (ra.managed_identity_key != null ? 1 : 0) + (ra.assign_to_caller ? 1 : 0)) == 1` (10 existing + 1 new for `resource_groups`)
- [x] T071 [FR-029] Update all 21 `principal_id` resolution lines in `main.tf` to check `ra.assign_to_caller` first: `ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ...`
- [x] T072 [FR-029] Update all role_assignments descriptions: add `assign_to_caller` attribute documentation and mutual exclusivity notes (15 standard blocks + 1 `resource_groups` + 2 Note callouts + 1 Pattern note)
- [x] T073 [FR-029] Add `assign_to_caller = optional(bool, false)` to all role_assignments blocks in 4 example `variables.tf` files (minimal: 15, full: 21, vnet_hub: 15, vwan_hub: 15)
- [x] T074 [FR-029] Add `assign_to_caller = true` demo to full example `terraform.tfvars` (key vault `kv_admin_caller` role assignment)
- [x] T075 [FR-029] Run `terraform validate` on root and all 4 examples
- [x] T076 [FR-029] Regenerate READMEs via `terraform-docs .` on root and all 4 examples
- [x] T077 [FR-029] Update spec.md (FR-029), plan.md (Phase 5), and tasks.md (Phase 12)

**Checkpoint**: `assign_to_caller` available on all role_assignments blocks across all variables. Validation enforces 3-way mutual exclusivity. All configs validate. READMEs regenerated.

---

## Phase 13: FR-030 & FR-031 — Key-Based CMK References and Managed Identity Keys (Complete)

**Prerequisites**: Phase 12 complete.

### Acceptance Criteria

**FR-030**: `customer_managed_key` objects MUST support `key_vault_key`, `key_key`, and `user_assigned_identity.key` for key-based references to pattern-managed resources. Mutual exclusivity validated. `main.tf` resolves keys to resource IDs/names. Examples and docs updated.

**FR-031**: `managed_identities` inline objects MUST support `user_assigned_keys` that resolves to resource IDs and merges with `user_assigned_resource_ids`. Examples and docs updated.

**Independent Test**: Setting `key_vault_key = "kv_shared"` and `key_key = "cmk_sa"` resolves to the key vault resource ID and key name. Setting both `key_vault_resource_id` and `key_vault_key` triggers validation error. Setting `user_assigned_keys = ["mi_app"]` merges with explicit resource IDs. `terraform validate` passes on root and all examples.

### Implementation

- [x] T078 [FR-030/FR-031] Add `managed_identity_resource_ids` and `key_vault_resource_ids` locals in `locals.tf`
- [x] T079 [FR-030] Update `customer_managed_key` type definitions in root `variables.tf`: add `key_vault_key`, `key_key`, `user_assigned_identity.key`; change `key_vault_resource_id`, `key_name`, `user_assigned_identity.resource_id` to `optional(string)` (2 blocks: `log_analytics_workspace_configuration`, `storage_accounts`)
- [x] T080 [FR-030] Add CMK validation blocks: mutual exclusivity for `key_vault_resource_id`/`key_vault_key`, `key_name`/`key_key`, `user_assigned_identity.resource_id`/`key`; dependency `key_key` requires `key_vault_key` (2 variables × 4 validations = 8 new validation blocks)
- [x] T081 [FR-031] Add `user_assigned_keys = optional(set(string), [])` to `managed_identities` inline type in `storage_accounts` root `variables.tf`
- [x] T082 [FR-030] Update `main.tf` CMK resolution for `log_analytics_workspace_configuration` and `storage_accounts`: resolve `key_vault_key` → `local.key_vault_resource_ids`, `key_key` → key vault keys map name, `user_assigned_identity.key` → `local.managed_identity_resource_ids`
- [x] T083 [FR-031] Update `main.tf` `managed_identities` passthrough for `storage_accounts`: resolve `user_assigned_keys` via `local.managed_identity_resource_ids` and merge with `user_assigned_resource_ids` using `setunion`
- [x] T084 [FR-030/FR-031] Update `customer_managed_key` and `managed_identities` descriptions in root `variables.tf` with new fields, mutual exclusivity notes, and key-based reference documentation
- [x] T085 [FR-030] Update `customer_managed_key` type definitions in all example `variables.tf` files (LAW: 4 files; storage: full only)
- [x] T086 [FR-031] Update `managed_identities` type definition in full example `variables.tf`
- [x] T087 [FR-030/FR-031] Add demos to full example `terraform.tfvars`: key vault `keys` entry, storage account `customer_managed_key` with key-based references, `managed_identities` with `user_assigned_keys`
- [x] T088 [FR-030/FR-031] Run `terraform validate` on root and all 4 examples
- [x] T089 [FR-030/FR-031] Regenerate READMEs via `terraform-docs .` on root and all 4 examples
- [x] T090 [FR-030/FR-031] Update spec.md (FR-030, FR-031), plan.md (Phase 6), and tasks.md (Phase 13)

**Checkpoint**: Key-based CMK references and managed identity keys work across all relevant variables. Validation enforces mutual exclusivity. All configs validate. READMEs regenerated.

---

## Phase 14: FR-032 & FR-033 — Backup Vault and Recovery Services Vault (Complete)

- [x] T091 [FR-032] Research AVM module interfaces for `avm-res-dataprotection-backupvault` v2.0.3 and `avm-res-recoveryservices-vault` v0.3.3
- [x] T092 [FR-032] Study existing pattern linking behaviour (resource_group_key, role_assignments, private_endpoints, diagnostic_settings, managed_identities, CMK)
- [x] T093 [FR-032] Add `backup_vaults` variable to root `variables.tf` with full type definition, AVM-style description, and validation blocks (role assignment XOR, CMK mutual exclusivity)
- [x] T094 [FR-033] Add `recovery_services_vaults` variable to root `variables.tf` with full type definition, AVM-style description, and validation blocks
- [x] T095 [FR-032] Add `module "backup_vault"` call in `main.tf` with all pattern resolution logic (resource_group_key, location, tags, CMK key refs, managed_identities user_assigned_keys, role_assignments 3-way, diagnostic_settings use_default_log_analytics)
- [x] T096 [FR-033] Add `module "recovery_services_vault"` call in `main.tf` with all pattern resolution logic including private_endpoints (vnet_key/subnet_key, DNS zone keys)
- [x] T097 [FR-032/FR-033] Add outputs for `backup_vaults` (resource_id, name) and `recovery_services_vaults` (resource_id) in `outputs.tf`
- [x] T098 [FR-032/FR-033] Add variable type definitions to full example `variables.tf`
- [x] T099 [FR-032/FR-033] Add demo entries in full example `terraform.tfvars`
- [x] T100 [FR-032/FR-033] Run `terraform init -upgrade` and `terraform validate` on root + all 4 examples (all pass)
- [x] T101 [FR-032/FR-033] Update spec.md (FR-032, FR-033), plan.md (Phase 7), and tasks.md (Phase 14)
- [x] T102 [FR-032/FR-033] Regenerate terraform-docs README for root + all 4 example directories

**Checkpoint**: Backup Vault and Recovery Services Vault modules fully integrated with all pattern linking behaviours. All configs validate. READMEs regenerated.

---

## Phase 15: FR-034 — principal_type Auto-Resolution (Complete)

- [x] T103 [FR-034] Update all role_assignment blocks in `main.tf` (22 occurrences across all resource modules and their private_endpoints) to auto-resolve `principal_type` to `"ServicePrincipal"` when `managed_identity_key` is not null, falling back to `ra.principal_type` otherwise. Skip `resource_groups` role_assignments (no `managed_identity_key`).
- [x] T104 [FR-034] Update standalone `module "role_assignment"` in `main.tf` with the same auto-resolution logic.
- [x] T105 [FR-034] Add `principal_type = "User"` with inline comment to all `assign_to_caller = true` entries in `examples/full/terraform.tfvars` (3 entries: kv_admin_caller, BV deployer_reader, RSV deployer_reader).
- [x] T106 [FR-034] Update spec.md (FR-034), plan.md (Phase 8), and tasks.md (Phase 15).
- [x] T107 [FR-034] Run `terraform validate` on root + all 4 examples.
- [x] T108 [FR-034] Regenerate terraform-docs README for root + all 4 example directories.

**Checkpoint**: principal_type auto-resolved to "ServicePrincipal" for managed-identity-backed role assignments. Examples annotated with User principal_type. All configs validate. READMEs regenerated.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion (T002 for AVM module sources) — BLOCKS all variable rewrites
- **Phase 3 (Trivial/Low)**: Depends on Phase 2 (template established with `resource_groups`)
- **Phase 4 (Medium)**: Depends on Phase 2; can start in parallel with Phase 3 (different line ranges in `variables.tf`)
- **Phase 5 (High/Very High)**: Depends on Phase 2; can start in parallel with Phase 3/4 (different line ranges)
- **Phase 6 (US3 Audit)**: Depends on ALL variable rewrites complete (Phases 3–5)
- **Phase 7 (US4 Rendering)**: Depends on Phase 6 (pattern notes may affect rendering)
- **Phase 8 (Polish)**: Depends on Phase 7 completion
- **Phase 9 (FR-026 managed_identity_key)**: Depends on Phase 8 completion (all descriptions must be finalized before modifying types and adding validations)
- **Phase 10 (FR-027 enable_telemetry)**: Depends on Phase 9 completion
- **Phase 11 (FR-028 name_random_suffix_configuration)**: Depends on Phase 10 completion
- **Phase 12 (FR-029 assign_to_caller)**: Depends on Phase 11 completion
- **Phase 13 (FR-030/FR-031 CMK keys & MI keys)**: Depends on Phase 12 completion
- **Phase 14 (FR-032/FR-033 Backup Vault & Recovery Services Vault)**: Depends on Phase 13 completion (uses locals, CMK key refs, MI user_assigned_keys patterns established in prior phases)
- **Phase 15 (FR-034 principal_type Auto-Resolution)**: Depends on Phase 14 completion (modifies role_assignment blocks established in prior phases)

### User Story Dependencies

- **US1/US2 (P1)**: Phases 2–5. No dependencies on US3/US4.
- **US3 (P2)**: Phase 6. Depends on US1/US2 completion (all descriptions must be written before auditing pattern notes)
- **US4 (P2)**: Phase 7. Depends on US3 (pattern note fixes may change rendering)

### Within Each Phase

- Each variable rewrite follows the per-variable checklist from quickstart.md Step 3:
  1. Read AVM module's variable description
  2. Copy AVM text verbatim for matching attributes (FR-003)
  3. Fix known copy-paste bugs (research.md §6)
  4. Add `(Required)`/`(Optional)` markers to every leaf (FR-002)
  5. Add "deliberately arbitrary" for `map(object)` types (FR-004)
  6. Document standard interface blocks using contract templates
  7. Add cross-reference key documentation (FR-016)
  8. Add pattern notes in `> **Pattern note:**` format (FR-009)
  9. Document mutual exclusivity with inline + callout (FR-017)
  10. Remove any `Uses:`/`See:` lines (FR-001)
  11. Verify NO type/default/validation changes (FR-010)
- Validation checkpoints at end of each phase confirm no regressions

### Parallel Opportunities

- **Phase 3, 4, 5** can theoretically proceed in parallel since they modify different line ranges within `variables.tf`
- Within **Phase 5**, each high-complexity variable has its own validate step (T021, T023, T025, T027), allowing independent progress
- All **US3 audit tasks** (T028–T032) are read-only checks that can run in parallel
- All **Setup tasks** (T001–T003) can run in parallel

---

## Parallel Example: Phase 5 (High & Very High Complexity)

```text
# Each variable touches different line ranges — can be done independently:
T020+T021: log_analytics_workspace_configuration (L71–L210)
T022+T023: key_vaults (L634–L820)
T024+T025: virtual_networks (L333–L510)
T026+T027: storage_accounts (L1000–L1442)
```

---

## Implementation Strategy

### MVP First (Phase 2 + Phase 3)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (`resource_groups` template validated)
3. Complete Phase 3: Trivial & Low Complexity
4. **STOP and VALIDATE**: 8/17 variables complete — functional MVP
5. Run `terraform-docs .` to confirm rendering for completed variables

### Incremental Delivery

1. Phase 1+2 → Foundation + template validated (1/17 variables)
2. Phase 3 → 8/17 variables done (MVP) → Validate
3. Phase 4 → 14/17 variables done → Validate
4. Phase 5 → 17/17 variables done → SC-001 met
5. Phase 6 → Pattern notes audited → US3 confirmed
6. Phase 7 → terraform-docs clean → SC-004, SC-005 confirmed
7. Phase 8 → All SCs verified → Feature complete

### Sequential Execution (Single Developer)

1. Work through phases 1–8 in order
2. Within each phase, follow variable priority order from data-model.md
3. Commit after each phase checkpoint for safety

---

## Notes

- All work targets ONE file: `variables.tf` at repository root (description attributes only)
- READMEs are machine-generated by `terraform-docs` — not hand-edited
- NO type, default, or validation changes permitted (FR-010) — **except** FR-026 `managed_identity_key` universalisation
- Each variable rewrite follows the same 11-item checklist from quickstart.md Step 3
- The `storage_accounts` variable is by far the largest (~80+ attrs, 6 AVM source files)
- The standalone `role_assignments` (L821) uses a DIFFERENT template (§3f) than nested `role_assignments` blocks (§3b) — see data-model.md WARNING
- `managed_identities` `role_assignments` uses `scope` not `principal_id` — uses contracts §3c, NOT §3b
- Nested `map(object)` attributes (e.g., `routes` in `route_tables`, `subnets`/`peerings` in `virtual_networks`) also need the "deliberately arbitrary" statement per checklist finding CHK005
- For `optional(string)` with no default, use "Defaults to `null`." per checklist finding CHK009
- Storage sub-diagnostics (`diagnostic_settings_blob`, etc.) reuse the §3d template per checklist findings CHK011/CHK032
- The codebase uses `<<-EOT` heredoc style — contracts use `<<DESCRIPTION` as a template placeholder; match whatever the codebase currently uses per checklist finding CHK019
