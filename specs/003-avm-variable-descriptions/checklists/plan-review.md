# Plan Review Checklist: AVM-Style Variable Descriptions

**Purpose**: Validate requirements quality across spec.md, research.md, data-model.md, contracts/description-style.md, and quickstart.md — testing completeness, coverage, and consistency of the requirements themselves.  
**Created**: 2026-03-17  
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md)  
**Focus**: Completeness + Coverage (primary), Consistency (secondary)  
**Depth**: Standard  
**Audience**: Reviewer (pre-tasks gate)

## Requirement Completeness — Variable Coverage

- [ ] CHK001 - Are all 17 variables explicitly enumerated by name in the data-model.md inventory? [Completeness, Spec §SC-001]
- [ ] CHK002 - Does the data-model.md specify the estimated leaf attribute count for each of the 17 variables? [Completeness, data-model.md §Variable Inventory]
- [ ] CHK003 - Is the `byo_log_analytics_workspace` variable's description treatment defined (it has no AVM module — what is the source of truth)? [Gap, Spec §FR-001]
- [ ] CHK004 - Is the `vhub_connectivity_definitions` variable's AVM source mapping specified, given it maps to a submodule rather than a primary AVM module? [Coverage, data-model.md §AVM Module Source Files]
- [ ] CHK005 - Are requirements defined for variables that are `object({...})` (not `map(object)`) — specifically `byo_log_analytics_workspace`, `log_analytics_workspace_configuration`, and `flowlog_configuration` — regarding whether they get the "deliberately arbitrary" statement? [Clarity, Spec §FR-004]
- [ ] CHK006 - Is the `role_assignments` variable (L821, standalone — not the nested block) explicitly distinguished from the nested `role_assignments` blocks in other variables? [Clarity, data-model.md §Variable Inventory]

## Requirement Completeness — Attribute Coverage

- [ ] CHK007 - Does the spec or data-model define which specific leaf attributes exist for each variable, or only estimated counts? [Completeness, Gap]
- [ ] CHK008 - Are requirements defined for documenting `nullable = false` attributes (if any exist in variables.tf)? [Coverage, Gap]
- [ ] CHK009 - Are requirements specified for how `optional(type, default)` attributes should communicate their default in the description text? [Completeness, Spec §Edge Cases]
- [ ] CHK010 - Is the complete attribute list for `vhub_connectivity_definitions` (routing, associated_route_table, propagated_route_tables, etc.) documented anywhere? [Gap, data-model.md]
- [ ] CHK011 - Are requirements defined for storage account sub-diagnostics (`diagnostic_settings_blob`, `diagnostic_settings_file`, `diagnostic_settings_queue`, `diagnostic_settings_table`) if they exist in the pattern? [Coverage, research.md §7]

## Requirement Completeness — Cross-Reference Keys

- [ ] CHK012 - Does the data-model cross-reference key table cover all pattern-specific keys that exist in the actual `variables.tf` type definitions? [Completeness, data-model.md §Cross-Reference Key Attributes]
- [ ] CHK013 - Are requirements specified for cross-reference keys that appear inside deeply nested objects (e.g., `storage_accounts.*.customer_managed_key.key_vault_key`)? [Coverage, Spec §FR-016]
- [ ] CHK014 - Is there a requirement specifying what happens when a cross-reference key has no valid target (e.g., `managed_identity_key` referencing a non-existent identity)? [Edge Case, Gap]

## Requirement Clarity — Style Contract

- [ ] CHK015 - Is the contract §3b `role_assignments` template missing `(Required)`/`(Optional)` markers on `role_definition_id_or_name` and `principal_id`? [Clarity, contracts/description-style.md §3b]
- [ ] CHK016 - Does the contract specify how `> Note:` and `> **Pattern note:**` callouts interact when both appear in the same description block? [Clarity, contracts/description-style.md §4]
- [ ] CHK017 - Is the contract's nesting depth rule (2-space indent per level) validated against actual terraform-docs rendering behavior for 3+ nesting levels? [Clarity, contracts/description-style.md §2]
- [ ] CHK018 - Is "maybe" vs "may be" in the deliberately arbitrary statement explicitly called out as intentional in the contract (not just research.md)? [Clarity, contracts/description-style.md §1]
- [ ] CHK019 - Does the contract define the heredoc delimiter name (e.g., `DESCRIPTION` vs `DESC` vs `EOT`) to ensure consistency across all 17 variables? [Gap, contracts/description-style.md §7]

## Requirement Clarity — Ambiguous Terms

- [ ] CHK020 - Is "light polish" for `location` and `tags` (FR-018) quantified with specific changes allowed vs prohibited? [Ambiguity, Spec §FR-018]
- [ ] CHK021 - Is "lightly edited for grammar or clarity" (Assumptions §4) bounded — what grammar changes are permitted vs which would violate FR-003's verbatim requirement? [Ambiguity, Spec §Assumptions]
- [ ] CHK022 - Is "pattern-authored" (Edge Cases §4) defined — does it get a specific marker or callout, and does it differ from the `> **Pattern note:**` format? [Ambiguity, Spec §Edge Cases]
- [ ] CHK023 - Is "behavioral notes" (User Story 1, Acceptance Scenario 1) defined — what constitutes a behavioral note vs a description? [Ambiguity, Spec §US-1]

## Requirement Consistency — Across Artifacts

- [ ] CHK024 - Does the contract §3b role_assignments field list (9 fields) match the field list in research.md §4b and the spec FR-006? [Consistency, contracts/description-style.md §3b vs research.md §4b vs Spec §FR-006]
- [ ] CHK025 - Does the contract's `lock` template (§3a) match the canonical text documented in research.md §4a? [Consistency, contracts/description-style.md §3a vs research.md §4a]
- [ ] CHK026 - Does the data-model's "Repeated Interface Blocks" table match the contract's template sections (§3a-§3e)? [Consistency, data-model.md vs contracts/description-style.md]
- [ ] CHK027 - Does the data-model list 10 cross-reference keys while the contract §4 only shows a `resource_group_key` example — are all 10 keys' formats specified? [Consistency, Gap]
- [ ] CHK028 - Does the quickstart's per-variable checklist (Step 3) align with all 18 FRs in the spec? [Consistency, quickstart.md §Step 3 vs Spec §FRs]

## Scenario Coverage — Interface Block Variants

- [ ] CHK029 - Are requirements defined for how the managed_identity `role_assignments` variant interacts with `managed_identity_key` mutual exclusivity (FR-017)? [Coverage, Spec §FR-017 + research.md §8]
- [ ] CHK030 - Are requirements specified for which variables have `private_endpoints` blocks vs which do not? [Coverage, data-model.md §Repeated Interface Blocks]
- [ ] CHK031 - Is the `diagnostic_settings` block's `use_default_log_analytics` attribute documented for every variable that has `diagnostic_settings`, or only some? [Coverage, Spec §FR-007]
- [ ] CHK032 - Are requirements defined for the storage account's 4 sub-resource diagnostic settings (blob, file, queue, table) that follow a different pattern from the main `diagnostic_settings`? [Coverage, research.md §7]

## Scenario Coverage — Edge Cases & Exception Flows

- [ ] CHK033 - Are requirements defined for attributes that exist in the pattern's type definition but have no corresponding AVM source description (pattern-only attributes)? [Edge Case, Spec §Edge Cases §4]
- [ ] CHK034 - Are requirements specified for attributes where the AVM source uses a different type than the pattern (e.g., AVM has `string` but pattern wraps it in `optional(string)`)? [Edge Case, Gap]
- [ ] CHK035 - Is the fallback behavior specified for when `.terraform/modules/` is not populated (missing AVM source)? [Edge Case, Spec §Dependencies]
- [ ] CHK036 - Are requirements defined for handling AVM modules that may have been updated since the research extraction (version drift between research and implementation)? [Edge Case, Gap]
- [ ] CHK037 - Is the behavior specified when a `validation` block's constraint cannot be meaningfully expressed in the description text (e.g., complex regex patterns)? [Edge Case, Spec §FR-017]

## Acceptance Criteria Quality

- [ ] CHK038 - Can SC-002 ("100% of nested attributes") be objectively verified — is there a definitive list of all nested attributes to check against? [Measurability, Spec §SC-002]
- [ ] CHK039 - Can SC-003 ("new user can populate terraform.tfvars") be objectively measured, or is it subjective? [Measurability, Spec §SC-003]
- [ ] CHK040 - Is SC-004 ("no rendering artifacts") quantified — what specific artifacts are checked for (broken bullets, orphaned text, mangled backticks, or others)? [Measurability, Spec §SC-004]
- [ ] CHK041 - Does the quickstart's final verification checklist (Step 6) map 1:1 to spec success criteria SC-001 through SC-006? [Traceability, quickstart.md §Step 6 vs Spec §SCs]

## Dependencies & Assumptions

- [ ] CHK042 - Is the assumption that "existing variable types, defaults, and validation blocks are correct" (Assumption §2) validated anywhere, or taken on faith? [Assumption, Spec §Assumptions]
- [ ] CHK043 - Is the dependency on specific AVM module versions (14 modules) documented with what happens if versions change before implementation? [Dependency, Spec §Dependencies + research.md]
- [ ] CHK044 - Is the `terraform-docs` version requirement specified, given that rendering behavior may vary across versions? [Gap, quickstart.md §Prerequisites]

## Notes

- Check items off as completed: `[x]`
- Add comments or findings inline after each item
- Items with `[Gap]` indicate potentially missing requirements
- Items with `[Ambiguity]` indicate terms that may need clarification before implementation
- Total items: 44 (Completeness: 14, Clarity: 9, Consistency: 5, Coverage: 8, Edge Cases: 5, Acceptance: 4, Dependencies: 3)
