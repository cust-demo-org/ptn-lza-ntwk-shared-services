# Feature Specification: AVM-Style Variable Descriptions

**Feature Branch**: `003-avm-variable-descriptions`  
**Created**: 2026-03-17  
**Status**: Draft  
**Input**: User description: "Improve variable descriptions in the main pattern module so they are verbose, consistent, and aligned with Azure Verified Module (AVM) documentation style."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Self-Service tfvars Authoring (Priority: P1)

A Terraform operator wants to populate `terraform.tfvars` for the pattern module without reading the module source code. They open the generated `terraform-docs` README or run `terraform-docs .` and expect every attribute — including deeply nested ones like `role_assignments.*` and `lock.*` — to be fully documented with types, defaults, required/optional markers, and behavioral notes.

**Why this priority**: This is the primary reason the descriptions exist. If a user cannot understand how to configure a variable from its description alone, the documentation has failed its core purpose.

**Independent Test**: A new user can populate a complete `terraform.tfvars` for the `full` example using only the README and variable descriptions, without consulting AVM module source files.

**Acceptance Scenarios**:

1. **Given** a user reading the terraform-docs output, **When** they look at any variable, **Then** every nested attribute is documented with `(Required)`/`(Optional)` markers, allowed values, defaults, and behavioral notes.
2. **Given** a user configuring `key_vaults.role_assignments`, **When** they read the description, **Then** they see each child attribute (`role_definition_id_or_name`, `principal_id`, `description`, `skip_service_principal_aad_check`, `condition`, `condition_version`, `delegated_managed_identity_resource_id`, `principal_type`) documented individually.
3. **Given** a user configuring `storage_accounts.blob_properties`, **When** they read the description, **Then** they see all nested objects (`container_delete_retention_policy`, `delete_retention_policy`, `restore_policy`, `cors_rule`) documented with their child attributes.

---

### User Story 2 - AVM Consistency (Priority: P1)

A contributor reviewing the pattern module expects variable descriptions to use the same style as upstream AVM modules: backtick-wrapped field names, `(Required)`/`(Optional)` markers, bullet-list format, and explicit mention of deliberate arbitrary map keys.

**Why this priority**: Consistency with AVM style is a hard requirement, not a nice-to-have. The pattern wraps AVM modules and should not introduce a separate documentation style.

**Independent Test**: Compare any variable description in the rewritten `variables.tf` against its upstream AVM module's variable description. Structural format, markers, and wording (excluding pattern-specific additions) must match.

**Acceptance Scenarios**:

1. **Given** any variable description in the pattern module, **When** compared to the corresponding AVM module variable description, **Then** AVM-sourced text is reused verbatim (not paraphrased), with pattern-specific notes clearly appended.
2. **Given** a variable whose type is `map(object({...}))`, **When** a user reads the description, **Then** it explicitly states that the map key is deliberately arbitrary to avoid plan-time issues with unknown keys.

---

### User Story 3 - Pattern-Specific Context (Priority: P2)

A user configuring the pattern needs to understand pattern-specific behavior (e.g., `location` defaulting to `var.location`, `tags` merging with `var.tags`, `use_default_log_analytics` auto-filling workspace_resource_id). These notes are not in the upstream AVM description and must be clearly distinguished.

**Why this priority**: Pattern-specific context is what distinguishes this module from raw AVM calls. Without it, users would still need to read source code.

**Independent Test**: Every pattern-specific note can be identified by reading the description alone — it is not mixed into AVM-sourced text without attribution.

**Acceptance Scenarios**:

1. **Given** a variable with pattern-specific defaulting (e.g., `location`), **When** a user reads the description, **Then** the AVM-sourced text appears first, followed by a clearly separated pattern note (e.g., "Defaults to `var.location` if not specified.").
2. **Given** a variable with `use_default_log_analytics`, **When** a user reads the diagnostic_settings block, **Then** the pattern-specific boolean is documented with its default, behavior when true, and behavior when false.

---

### User Story 4 - terraform-docs Rendering (Priority: P2)

A CI pipeline generates a README via `terraform-docs`. The rewritten descriptions must render cleanly in Markdown without broken indentation, orphaned bullets, or mangled backticks.

**Why this priority**: Descriptions that look correct in source but render poorly in terraform-docs defeat the purpose of the rewrite.

**Independent Test**: Run `terraform-docs .` after the rewrite and visually inspect the generated README for all 17 variables. No rendering artifacts.

**Acceptance Scenarios**:

1. **Given** the rewritten `variables.tf`, **When** `terraform-docs .` is executed, **Then** all descriptions render with proper bullet nesting, backtick formatting, and no orphaned text.

---

### Edge Cases

- What happens when a nested object has no child attributes to document (e.g., an empty block)? Omit the sub-list; document the object-level attribute only.
- How are `optional(...)` defaults communicated? Include "Defaults to `<value>`." in the attribute line.
- How are cross-reference keys documented (e.g., `resource_group_key`, `vnet_key`)? State that the value must match a key in the referenced map variable.
- What if an AVM module variable description is missing or vague for an attribute? Use the attribute's type constraint and Terraform provider documentation to write the description, and note it as pattern-authored.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every top-level variable in `variables.tf` MUST have its description rewritten in AVM bullet-list style with backtick-wrapped field names. The `Uses:` and `See:` provenance lines MUST be removed — `main.tf` already contains module source and version references.
- **FR-002**: Every nested attribute within an `object({...})` type MUST be individually documented with backtick-wrapped name, `(Required)` or `(Optional)` marker, and behavioral description. This applies to all leaf attributes without exception, including self-descriptive lifecycle policy fields and reverse peering mirror attributes.
- **FR-003**: Descriptions for attributes that map directly to AVM module inputs MUST reuse exact AVM wording. Pattern-specific notes MUST be appended, not interleaved.
- **FR-004**: Every `map(object({...}))` variable MUST state that the map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
- **FR-005**: Every `lock` block MUST document `kind` with allowed values (`"CanNotDelete"` and `"ReadOnly"`) and `name` with its optional/generated behavior.
- **FR-006**: Every `role_assignments` block MUST document all child attributes individually, including the note about `skip_service_principal_aad_check` applying only to service principals.
- **FR-007**: Every `diagnostic_settings` block MUST document all child attributes, including `use_default_log_analytics` with its pattern-specific defaulting behavior.
- **FR-008**: Every `private_endpoints` block MUST document all child attributes including `network_configuration`, `private_dns_zone`, `ip_configurations`, and sub-attributes.
- **FR-009**: Pattern-specific behaviors (location defaulting, tag merging, key cross-references) MUST be documented as clearly distinguished addenda — not mixed into AVM text.
- **FR-010**: Descriptions MUST NOT change variable types, defaults, or validation blocks — only `description` attributes are modified.
- **FR-011**: Descriptions MUST render cleanly with `terraform-docs` — proper Markdown nesting, no orphaned bullets, no broken backticks.
- **FR-012**: The `storage_accounts` variable MUST document all sub-objects including `blob_properties.*`, `share_properties.*`, `queue_properties.*`, `network_rules.*`, `containers.*`, `private_endpoints.*`, `managed_identities.*`, and all storage management policy rule attributes.
- **FR-013**: The `virtual_networks` variable MUST document `subnets.*` and `peerings.*` with all their nested attributes.
- **FR-014**: The `flowlog_configuration` variable MUST document `flow_logs.*` with all child attributes including `retention_policy.*`, `storage_account.*`, and `traffic_analytics.*`.
- **FR-015**: The `log_analytics_workspace_configuration` variable MUST document all nested objects including `identity.*`, `customer_managed_key.*`, `data_exports.*`, `linked_storage_accounts.*`, `tables.*`, `diagnostic_settings.*`, and `private_endpoints.*`.
- **FR-016**: Cross-reference keys (e.g., `resource_group_key`, `vnet_key`, `subnet_key`, `network_security_group_key`, `route_table_key`) MUST state the target variable map they reference.
- **FR-017**: Variables with `validation` blocks MUST mention the constraint in the description so users understand the rule without reading HCL. Mutual exclusivity constraints (e.g., `principal_id` vs `managed_identity_key`) MUST be documented both inline on each affected attribute's bullet AND in a `> Note:` callout after the attribute list.
- **FR-018**: The `location` and `tags` variables (simple scalars with no nested attributes) MUST receive a light polish only — paragraph style retained, backtick consistency applied, minor wording alignment — not a full AVM bullet-list rewrite.
- **FR-019**: The variable's HCL `type` definition MUST be the source of truth for attribute completeness — not the existing description or AVM README. Old descriptions may be incomplete summaries that omit deeply nested attributes. *(from L11)*
- **FR-020**: AVM source text MUST be critically reviewed for copy-paste artifacts before reuse. Known systematic bugs include unreplaced `<RESOURCE>` placeholders, wrong resource names in diagnostic_settings blocks, and typos in map descriptions. Blind paste of AVM text is prohibited. *(from L13)*
- **FR-021**: All variable files in an AVM module directory MUST be scanned when sourcing descriptions — not just the primary `variables.tf`. AVM modules may split variable definitions across multiple files (e.g., `variables.storageaccount.tf`, `variables.diagnostics.tf`, `variables.container.tf`). *(from L14)*
- **FR-022**: When multiple AVM description variants exist for the same interface block (e.g., 9-field vs 7-field `role_assignments`, standard vs short `lock`), the newest and most complete variant MUST be chosen as the canonical template and applied consistently across all variables. *(from L15)*
- **FR-023**: Design choices that omit standard interface blocks or pattern-specific fields (e.g., omitting `use_default_log_analytics` from the Log Analytics workspace's own `diagnostic_settings` to avoid circular self-references) MUST be documented in a `> **Pattern note:**` callout explaining the rationale. Omissions without explanation look like bugs. *(from L16)*
- **FR-024**: All cross-reference key attributes MUST be verified in a single post-rewrite audit pass across the entire file to ensure every occurrence names the correct target variable. Per-variable verification during writing is insufficient because drift accumulates across 17 variables. *(from L17)*
- **FR-025**: Post-rewrite consistency checks — cross-reference key targets, pattern note format, `use_default_log_analytics` documentation, and removal of provenance lines — MUST be automated via text search (grep/Select-String), not manual visual review. A 2000+ line file defeats manual inspection. *(from L21)*

### Key Entities

- **Variable description**: The `description` attribute of a Terraform `variable` block. The sole output artifact of this feature.
- **AVM source description**: The upstream Azure Verified Module's variable description, used as the authoritative text source.
- **Pattern-specific note**: Text added by this pattern that does not exist in the AVM source (e.g., defaulting to `var.location`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 17 variables in `variables.tf` have rewritten descriptions in AVM bullet-list style.
- **SC-002**: 100% of nested attributes within object types are individually documented — no attribute is left as "See AVM module variable" without inline documentation.
- **SC-003**: A new user can populate a complete `terraform.tfvars` for the `full` example using only the README without consulting module source code.
- **SC-004**: `terraform-docs .` generates a README with no rendering artifacts (broken bullets, orphaned text, mangled backticks).
- **SC-005**: `terraform validate` passes on the root module and all 4 examples after the description rewrite (confirming no structural changes).
- **SC-006**: Every `map(object({...}))` description includes the deliberate arbitrary key statement. The total count of "deliberately arbitrary" occurrences MUST be verified against the combined count of top-level `map(object)` variables and nested `map(object)` attributes. *(strengthened by L19)*

## Clarifications

### Session 2026-03-17

- Q: Should the `Uses:` and `See:` header lines be retained in the rewritten descriptions? → A: Remove them entirely. `main.tf` already contains module source/version references, so duplicating them in variable descriptions adds noise without value.
- Q: Should repeated standard blocks (`role_assignments`, `lock`, `diagnostic_settings`) be fully documented in every variable or cross-referenced? → A: Full inline documentation in every variable. Each variable's description must be self-contained so users never need to scroll to another variable.
- Q: For deeply nested self-descriptive attributes (lifecycle days, reverse peering), should every leaf get its own bullet or use parent-level grouping? → A: Every leaf attribute gets its own indented bullet — no exceptions, even for 14+ lifecycle fields or 30+ peering attributes.
- Q: How should mutual exclusivity between `principal_id` and `managed_identity_key` be communicated? → A: Both — inline mention on each attribute's bullet line plus a `> Note:` callout summarizing the rule.
- Q: Should `location` and `tags` (simple scalars with no nested attributes) be rewritten in full AVM bullet-list style? → A: Light polish only — keep paragraph style, add backtick consistency and minor wording alignment.

## Assumptions

- AVM module source is available locally under `.terraform/modules/` after running `terraform init` on any example.
- The existing variable types, defaults, and validation blocks are correct and must not be modified.
- The `resource_groups` variable description provided by the user is the reference style target — all other variables must match this level of detail.
- Descriptions sourced from AVM modules may be lightly edited for grammar or clarity, but semantic meaning must be preserved.
- Where AVM descriptions reference other AVM variables (e.g., "See the `lock` variable"), this feature inlines the full documentation rather than cross-referencing.

## Scope & Boundaries

### In Scope

- Rewriting all 17 `description` attributes in the root `variables.tf`.
- Reading AVM module source descriptions as the authoritative text source.
- Adding pattern-specific notes where applicable.
- Regenerating READMEs via `terraform-docs` after the rewrite.
- Running `terraform validate` to confirm no breakage.

### Out of Scope

- Changing variable types, defaults, or validation blocks.
- Updating example `variables.tf` descriptions (those are simpler wrappers and follow a different convention).
- Adding new variables or removing existing ones.
- Modifying `main.tf`, `locals.tf`, `outputs.tf`, or any other file.

## Dependencies

- `.terraform/modules/` must be populated via `terraform init` to read AVM source descriptions.
- `terraform-docs` must be available at the known path for README regeneration.
- Feature 002 (`002-testable-examples`) should be complete (it is) to avoid merge conflicts with the same `variables.tf` file.

## Lessons Learned (from Feature 002)

| # | Lesson | Applicable FR |
|---|--------|---------------|
| L1 | Verify types against `.terraform/modules/` source before changes | FR-010 (no type changes) |
| L2 | Use explicit boolean flags, not coalesce fallback | FR-007 (document `use_default_log_analytics`) |
| L3 | Phrase descriptions from the user's perspective | FR-002, FR-003 |
| L4 | Run grep sweep after structural changes | FR-011 (terraform-docs rendering) |
| L5 | Full example must pass `terraform validate` after changes | SC-005 |

---

## Lessons Learned (from Feature 003 Implementation)

### Execution Strategy

| # | Lesson | Detail |
|---|--------|--------|
| L6 | Phase by complexity, validate every phase | Ordering variables from trivial → low → medium → high → very-high let us establish a working template early, catch formatting issues on small variables, and build confidence before tackling the 80+ attribute monsters. Validating after every phase (not every variable) was the right cadence — fast enough to catch breaks, coarse enough not to bottleneck. |
| L7 | Start with one reference variable, then stamp the rest | Writing `resource_groups` first as the "template" variable was critical. Every subsequent variable rewrite was measured against it for style consistency. Without this anchor, drift would have crept in across 17 variables. |
| L8 | Group related variables per phase, not per user story | User stories (US1–US4) were cross-cutting—every variable contributed to US1 and US2 simultaneously. Organizing tasks by variable complexity rather than by story avoided redundant passes over the same file. |
| L9 | Defer audits until all rewrites are done | Pattern audit (Phase 6), rendering validation (Phase 7), and polish (Phase 8) only make sense after every variable is written. Running them incrementally would have required repeated full-file sweeps that get invalidated by the next rewrite. |

### Working with Large Files

| # | Lesson | Detail |
|---|--------|--------|
| L10 | Heredoc descriptions can grow very large — plan for it | `storage_accounts` (~260 description lines), `virtual_networks` (~120), `key_vaults` (~110), and `log_analytics_workspace_configuration` (~100) dominated the file size. Read the full type definition before writing the description so you know the scope upfront. |
| L11 | Read the type definition, not just the old description | The old descriptions were incomplete summaries. The type definition is the source of truth for which attributes exist. Writing a description from the old description would miss deeply nested attributes. |
| L12 | Token budget is a real constraint on very large variables | The `storage_accounts` variable spans ~450 lines of type definition plus ~260 lines of description. Expect context-window pressure on variables this size — plan to carry forward partial state across sessions rather than assuming single-session completion. |

### AVM Source Quality

| # | Lesson | Detail |
|---|--------|--------|
| L13 | AVM module descriptions have systematic copy-paste bugs | At least 4 distinct bugs found: `<RESOURCE>` placeholder not replaced, "Key Vault" text in non-Key-Vault modules, "container app environment" in managed_identity, and a "role flow logs" typo. Always read the AVM source critically rather than pasting blindly. |
| L14 | AVM modules split variables across multiple files | The storage account module uses 6 separate variable files. Always do a file scan of the AVM module directory before writing the description, not just read `variables.tf`. |
| L15 | AVM interface blocks have 3+ variants — pick the newest | `role_assignments` had 3 variants (9-field, 7-field, managed-identity-scope), `lock` had 3 (standard, short, indented), `diagnostic_settings` had copy-paste bugs. Deciding on the canonical variant early and sticking to it prevented inconsistency. |

### Pattern-Specific Concerns

| # | Lesson | Detail |
|---|--------|--------|
| L16 | Circular references need explicit documentation | The `log_analytics_workspace_configuration` diagnostic_settings block deliberately omits `use_default_log_analytics` because the workspace cannot send diagnostics to itself. This is a non-obvious design choice that must be called out in a pattern note — it would otherwise look like an oversight. |
| L17 | Cross-reference keys are the glue — audit them as a group | Seven key types (`resource_group_key`, `vnet_key`, `virtual_network_key`, `subnet_key`, `network_security_group_key`, `route_table_key`, `managed_identity_key`) appear across 13+ locations. Auditing them individually during each variable rewrite risks drift; a single sweep after all rewrites catches mismatches more reliably. |
| L18 | `description: false` in terraform-docs config is non-blocking but surprising | The project's `.terraform-docs.yml` suppresses description rendering. The descriptions still live in `variables.tf` and are visible via `terraform-docs json .` or direct file inspection, but the generated README doesn't show them. This is a project design choice — don't waste time "fixing" rendering of content that's intentionally hidden. |

### Process & Quality

| # | Lesson | Detail |
|---|--------|--------|
| L19 | "Deliberately arbitrary" is a measurable contract | Counting occurrences of "deliberately arbitrary" (61 in final file) and comparing against the known `map(object)` count is a fast, reliable acceptance check. Encode such counts as success criteria early. |
| L20 | `terraform validate` is the only gate that matters during description-only changes | Since only `description` attributes change, semantic errors are impossible — the only risk is heredoc syntax errors (unclosed EOT, bad escaping). `terraform validate` catches these instantly. A full plan or apply would be wasted effort. |
| L21 | Grep-based audits outperform manual review for consistency checks | Verifying cross-ref keys, pattern notes, `use_default_log_analytics` documentation, and removal of `Uses:`/`See:` lines was done entirely with grep/Select-String. Manual reading of a 2100+ line file would have missed something. |
| L22 | Validation blocks are implicit contracts — document them before users hit them | Four validation blocks enforce constraints that users will encounter as opaque errors if not documented. The description should preempt the error message by explaining the rule in plain language. |
