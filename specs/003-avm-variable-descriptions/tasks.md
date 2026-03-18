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

- [ ] T001 Verify branch `003-avm-variable-descriptions` is checked out and working tree is clean in repository root
- [ ] T002 Run `terraform init` in `examples/full/` to populate `.terraform/modules/` with all 14 AVM module sources
- [ ] T003 Verify `terraform-docs` executable is available at `C:\Users\minheinaung\AppData\Local\Microsoft\WinGet\Packages\Terraform-docs.Terraform-docs_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform-docs.exe`

---

## Phase 2: Foundational (Template Establishment)

**Purpose**: Establish the description rewrite template using the simplest complex variable (`resource_groups`), confirming the pattern works end-to-end before applying to all other variables

**⚠️ CRITICAL**: The `resource_groups` rewrite serves as the reference for all subsequent variables. Must pass validation before proceeding.

- [ ] T004 Rewrite `resource_groups` description (starting ~L23) in `variables.tf`: read AVM source from `examples/full/.terraform/modules/resource_group/variables.tf`, then rewrite following contracts/description-style.md §1 (map(object) top-level structure with "deliberately arbitrary" statement), §2 (attribute bullet format with Required/Optional markers), §3a (lock block template), §3b (role_assignments standard 9-field template), §4 (resource_group_key cross-reference note — N/A for resource_groups itself but establish tags pattern note); include all ~5 leaf attrs; remove any existing `Uses:` / `See:` provenance lines per FR-001
- [ ] T005 Validate the `resource_groups` rewrite: run `terraform validate` on root module and all 4 example directories (`examples/minimal`, `examples/vnet_hub`, `examples/vwan_hub`, `examples/full`); also run `terraform-docs .` on root module and spot-check rendered output for `resource_groups` to catch rendering issues early (FR-011)

**Checkpoint**: Template pattern validated — `resource_groups` description is the reference for all subsequent rewrites.

---

## Phase 3: US1/US2 — Trivial & Low Complexity Variables (P1)

**Goal**: Rewrite 6 simple variables to establish broad coverage quickly. Each description becomes self-contained for tfvars authoring (US1) using AVM-consistent formatting (US2).

**Independent Test**: A user can populate tfvars for these variables using only the description. `terraform validate` passes on root + 4 examples.

### Implementation

- [ ] T006 [US1] Rewrite `location` (starting ~L1) description in `variables.tf` — light polish only per FR-018: read current description, backtick-wrap inline values (e.g., `var.location`), ensure description ends with a period, verify sentence is meaningful to a consumer per constitution VI; add `> **Pattern note:** Defaults to the value of \`var.location\`.` if pattern defaulting applies; do NOT convert to bullet-list format
- [ ] T007 [US1] Rewrite `tags` (starting ~L10) description in `variables.tf` — light polish only per FR-018: read current description, backtick-wrap inline values, ensure description ends with a period, note the type is `map(string)`; add `> **Pattern note:** Merged with \`var.tags\`.` to document the merge behavior; do NOT convert to bullet-list format
- [ ] T008 [US1] Rewrite `byo_log_analytics_workspace` (starting ~L58) description in `variables.tf`: this is a pattern-specific variable (no direct AVM source), follow contracts §1 (single object structure) and §2 (attribute bullets); ~2 attrs (`resource_id`, `workspace_id`); add pattern note explaining this is for bringing an existing LAW
- [ ] T009 [US1] Rewrite `byo_private_dns_zone_links` (starting ~L562) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/` private_dns_zone link submodule, follow contracts §1 (map(object) with "deliberately arbitrary"), §2, §4 (cross-reference keys: `virtual_network_key` references `virtual_networks` variable); ~5 attrs
- [ ] T010 [US1] Rewrite `route_tables` (starting ~L287) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/route_table/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments standard 9-field), §4 (`resource_group_key` references `resource_groups`); ~12 attrs including `routes` nested map(object) with its own "deliberately arbitrary" statement
- [ ] T011 [US1] Rewrite standalone `role_assignments` (starting ~L821) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/role_assignment/variables.tf`, follow contracts §3f (standalone variant — NOT §3b); ~6 attrs with `scope`, `managed_identity_key`; document mutual exclusivity of `principal_id` vs `managed_identity_key` per FR-017 (inline on each attribute + `> Note:` callout); WARNING: this uses `avm-res-authorization-roleassignment` and has different fields than nested role_assignments blocks
- [ ] T012 [US1] Validate Phase 3 rewrites: run `terraform validate` on root module and all 4 example directories; also run `terraform-docs .` on root module and spot-check rendered output for Phase 3 variables to catch rendering issues early (FR-011)

**Checkpoint**: 8 of 17 variables complete (including `resource_groups` from Phase 2). All trivial/low-complexity variables validated.

---

## Phase 4: US1/US2 — Medium Complexity Variables (P1)

**Goal**: Rewrite 6 medium-complexity variables with standard interface blocks (lock, role_assignments, diagnostic_settings) and cross-reference keys. Completes the core of the variable inventory.

**Independent Test**: Each description documents all nested attributes with `(Required)`/`(Optional)` markers. Cross-reference keys state the correct target variable. `terraform validate` passes.

### Implementation

- [ ] T013 [US1] Rewrite `network_security_groups` (starting ~L211) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/network_security_group/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings — fix "Key Vault" copy-paste bug per research.md §6), §4 (`resource_group_key`); ~18 attrs including `security_rules` nested map(object) with protocol, source/destination port ranges, access, direction, priority
- [ ] T014 [US1] Rewrite `private_dns_zones` (starting ~L511) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/private_dns_zone/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §4 (`resource_group_key`, `virtual_network_key` in `virtual_network_links` sub-object references `virtual_networks`); ~15 attrs
- [ ] T015 [US1] Rewrite `managed_identities` (starting ~L591) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/managed_identity/variables.tf`, follow contracts §1, §2, §3a (lock), §3c (role_assignments MANAGED IDENTITY VARIANT — uses `scope` not `principal_id`, only 6 fields; fix "container app environment" copy-paste bug per research.md §6), §4 (`resource_group_key`); ~12 attrs including `federated_identity_credentials`
- [ ] T016 [US1] Rewrite `vhub_connectivity_definitions` (starting ~L851) description in `variables.tf`: read AVM source from the vhub_vnet_connection submodule under `examples/full/.terraform/modules/` (exact path may be nested — run `Get-ChildItem -Recurse -Filter variables.tf` under `.terraform/modules/` during T002 to locate it), follow contracts §1, §2, §4 (`vnet_key` references `virtual_networks`); ~10 attrs including routing config (`associated_route_table`, `propagated_route_tables`)
- [ ] T017 [US1] Rewrite `bastion_hosts` (starting ~L903) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/bastion_host/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings), §4 (`resource_group_key`, `subnet_key` in `ip_configuration` references `virtual_networks[].subnets`); ~20 attrs including `ip_configuration` sub-object and `sku`
- [ ] T018 [US1] Rewrite `flowlog_configuration` (starting ~L1443) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/network_watcher/variables.tf`, follow contracts §1 (single object wrapping `flow_logs` map(object)), §2, §4 (`vnet_key` in flow_logs references `virtual_networks`); ~15 attrs including `retention_policy`, `storage_account` (nested object with `key` field — this is NOT a cross-reference key, it is a nested field named `key` inside a `storage_account` object), `traffic_analytics`; fix "A map of role flow logs" typo per research.md §6; add pattern note that network_watcher is auto-created
- [ ] T019 [US1] Validate Phase 4 rewrites: run `terraform validate` on root module and all 4 example directories

**Checkpoint**: 14 of 17 variables complete. All medium-complexity variables validated.

---

## Phase 5: US1/US2 — High & Very High Complexity Variables (P1)

**Goal**: Rewrite the 4 most complex variables with the deepest nesting and largest attribute counts. Each variable gets its own validation step due to size and risk.

**Independent Test**: Every leaf attribute is individually documented — no attribute left undocumented. Storage accounts merges descriptions from all 6 AVM source files. `terraform validate` passes after each variable.

### Implementation

- [ ] T020 [US1] Rewrite `log_analytics_workspace_configuration` (starting ~L71) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/log_analytics_workspace/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings), §3e (private_endpoints with full ip_configurations sub-block), §5 (`use_default_log_analytics` pattern-specific boolean); ~45 attrs across `identity`, `customer_managed_key`, `data_exports`, `tables`, `linked_storage_accounts`, `diagnostic_settings`, `private_endpoints`, `lock`, `role_assignments`
- [ ] T021 [US1] Validate `log_analytics_workspace_configuration` rewrite: run `terraform validate` on root module and all 4 example directories
- [ ] T022 [US1] Rewrite `key_vaults` (starting ~L634) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/key_vault/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings), §3e (private_endpoints), §4 (`resource_group_key`, `subnet_key` in private_endpoints references `virtual_networks[].subnets`, `managed_identity_key` references `managed_identities`); ~50 attrs across `contacts`, `keys` (with `key_opts`, `rotation_policy` sub-objects), `secrets`, `network_acls`, `private_endpoints`, `diagnostic_settings`, `lock`, `role_assignments`
- [ ] T023 [US1] Validate `key_vaults` rewrite: run `terraform validate` on root module and all 4 example directories
- [ ] T024 [US1] Rewrite `virtual_networks` (starting ~L333) description in `variables.tf`: read AVM source from `examples/full/.terraform/modules/virtual_network/variables.tf`, follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings — fix "Key Vault" copy-paste bug per research.md §6), §4 (`resource_group_key`, `network_security_group_key` in subnets references `network_security_groups`, `route_table_key` in subnets references `route_tables`); ~55 attrs — document ALL ~30 peering attributes and ALL ~15 subnet attributes individually per clarification Q3; `subnets` and `peerings` are both nested map(object) with their own "deliberately arbitrary" statements
- [ ] T025 [US1] Validate `virtual_networks` rewrite: run `terraform validate` on root module and all 4 example directories
- [ ] T026 [US1] Rewrite `storage_accounts` (starting ~L1000) description in `variables.tf`: read AVM sources from ALL 6 files per research.md §7 — `examples/full/.terraform/modules/storage_account/variables.tf`, `variables.storageaccount.tf`, `variables.diagnostics.tf`, `variables.container.tf`, `variables.queue.tf`, `variables.share.tf`; follow contracts §1, §2, §3a (lock), §3b (role_assignments), §3d (diagnostic_settings for MAIN resource + `diagnostic_settings_blob`, `diagnostic_settings_file`, `diagnostic_settings_queue`, `diagnostic_settings_table` sub-diagnostics all reusing §3d template), §3e (private_endpoints), §4 (`resource_group_key`, `subnet_key`, `managed_identity_key`); ~80+ attrs across `blob_properties` (cors_rule, container_delete_retention_policy, delete_retention_policy, restore_policy), `share_properties` (cors_rule, retention_policy, smb), `queue_properties` (cors_rule, hour_metrics, logging, minute_metrics), `network_rules`, `containers`, `managed_identities`, `private_endpoints`, `diagnostic_settings`, `lock`, `role_assignments`
- [ ] T027 [US1] Validate `storage_accounts` rewrite: run `terraform validate` on root module and all 4 example directories

**Checkpoint**: All 17 variables rewritten (SC-001). All leaf attributes documented (SC-002). `map(object)` variables have "deliberately arbitrary" statement (SC-006).

---

## Phase 6: US3 — Pattern-Specific Context Audit (P2)

**Goal**: Verify all pattern-specific behaviors are documented with `> **Pattern note:**` callouts, clearly separated from AVM-sourced text per FR-009.

**Independent Test**: Every pattern-specific note is identifiable by reading the description alone — not mixed into AVM-sourced text without attribution.

### Implementation

- [ ] T028 [US3] Audit all cross-reference key descriptions in `variables.tf`: verify each of the 7 key attributes (`resource_group_key`, `vnet_key`, `virtual_network_key`, `subnet_key`, `network_security_group_key`, `route_table_key`, `managed_identity_key`) states its target variable per data-model.md § Cross-Reference Key Attributes and contracts §4
- [ ] T029 [US3] Audit all `use_default_log_analytics` occurrences in `variables.tf`: verify the pattern-specific boolean is documented in every `diagnostic_settings` block with default value (`true`), true-behavior (auto-sets `workspace_resource_id`), and false-behavior per contracts §5
- [ ] T030 [US3] Audit pattern-specific defaulting notes in `variables.tf`: verify `location` mentions `var.location` default, nested `tags` attributes mention merge with `var.tags`, and `flowlog_configuration` mentions network_watcher auto-creation per research.md §5 pattern note table
- [ ] T031 [US3] Verify all pattern notes use `> **Pattern note:**` callout format and appear AFTER AVM-sourced attribute descriptions (not interleaved) per contracts §4 and FR-009
- [ ] T032 [US3] Audit all `validation` blocks in `variables.tf`: scan for every `validation { ... }` block and verify the corresponding description mentions the constraint so users understand the rule without reading HCL per FR-017 (not limited to mutual exclusivity — includes any validation constraint)

**Checkpoint**: All pattern-specific context documented and correctly separated (US3 acceptance criteria met).

---

## Phase 7: US4 — terraform-docs Rendering Validation (P2)

**Goal**: Ensure all rewritten descriptions render cleanly in terraform-docs Markdown output with no artifacts.

**Independent Test**: Run `terraform-docs .` and inspect all 17 variable descriptions — no broken bullets, orphaned text, or mangled backticks.

### Implementation

- [ ] T033 [US4] Run `terraform-docs .` on root module and inspect rendered output for all 17 variable descriptions: check for proper bullet nesting, backtick formatting, no orphaned text, no broken indentation per contracts §7 rendering rules
- [ ] T034 [US4] Fix any rendering artifacts found in `variables.tf` descriptions (broken indentation, escaped backtick issues in heredocs, orphaned bullets, missing blank lines before `> Note:` callouts)
- [ ] T035 [US4] Regenerate all READMEs per quickstart Step 5: run `terraform-docs .` on root module and all 4 example directories (`examples/minimal`, `examples/vnet_hub`, `examples/vwan_hub`, `examples/full`)
- [ ] T036 [US4] Final `terraform validate` on root module and all 4 example directories — confirms SC-005

**Checkpoint**: terraform-docs output clean for all 17 variables (SC-004). All configs validate (SC-005).

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final verification against all success criteria

- [ ] T037 Verify SC-001 and SC-002: grep `variables.tf` for remaining `Uses:` or `See:` or `See AVM module` lines — all should return 0 matches (confirms all variables rewritten and no attributes deferred to external references)
- [ ] T038 Verify SC-006: grep `variables.tf` for "deliberately arbitrary" and count matches — must match the number of `map(object)` variables and nested `map(object)` attributes listed in data-model.md §3 (Deliberately Arbitrary Map Keys Statement)
- [ ] T039 Run quickstart.md Step 6 final verification checklist: SC-001 (17 variables), SC-002 (100% attrs), SC-003 (self-sufficient README), SC-004 (clean rendering), SC-005 (terraform validate pass), SC-006 (deliberately arbitrary statements)

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
- NO type, default, or validation changes permitted (FR-010)
- Each variable rewrite follows the same 11-item checklist from quickstart.md Step 3
- The `storage_accounts` variable is by far the largest (~80+ attrs, 6 AVM source files)
- The standalone `role_assignments` (L821) uses a DIFFERENT template (§3f) than nested `role_assignments` blocks (§3b) — see data-model.md WARNING
- `managed_identities` `role_assignments` uses `scope` not `principal_id` — uses contracts §3c, NOT §3b
- Nested `map(object)` attributes (e.g., `routes` in `route_tables`, `subnets`/`peerings` in `virtual_networks`) also need the "deliberately arbitrary" statement per checklist finding CHK005
- For `optional(string)` with no default, use "Defaults to `null`." per checklist finding CHK009
- Storage sub-diagnostics (`diagnostic_settings_blob`, etc.) reuse the §3d template per checklist findings CHK011/CHK032
- The codebase uses `<<-EOT` heredoc style — contracts use `<<DESCRIPTION` as a template placeholder; match whatever the codebase currently uses per checklist finding CHK019
