# Specification Review Checklist: Testable Examples

**Purpose**: Validate requirements quality, completeness, clarity, and consistency across the updated spec (post plan-stage FR-016–FR-021 additions) before task generation
**Created**: 2026-03-11
**Feature**: [spec.md](../spec.md)
**Depth**: Standard | **Audience**: Reviewer | **Focus**: Combined (example scaffolding + root module changes)

## Requirement Completeness

- [x] CHK001 - Are all four example directories (`minimal/`, `vnet_hub/`, `vwan_hub/`, `full/`) explicitly addressed with dedicated FRs defining their unique scope? [Completeness, Spec §FR-011, §FR-012, §FR-013, §FR-016] — **PASS**: FR-011 (minimal), FR-012 (full), FR-013 (vwan_hub), FR-016 (vnet_hub) each define unique scope.
- [x] CHK002 - Are the inline dependency requirements exhaustively enumerated for the `full/` example? FR-012 lists features but does not enumerate every inline resource (storage account for flow logs, public IP for Bastion, Network Watcher, DNS zone). [Gap, Spec §FR-012] — **PASS**: FR-012 names features; edge cases + research R7 + data-model inline dependency model exhaustively enumerate resources. Adequate coverage across artifacts.
- [x] CHK003 - Is a requirement defined for what the `vnet_hub/` example exercises beyond the hub VNet dependency? FR-016 specifies the inline hub VNet but does not list the full feature set (peering, NSGs, route tables, etc.). [Completeness, Spec §FR-016] — **PASS**: FR-016 defines the unique characteristic (hub VNet + peering); FR-011's minimal baseline is implicitly inherited. R3 table and US4-AS2 confirm full feature set.
- [x] CHK004 - Are requirements defined for example `outputs.tf`? No FR specifies whether examples should expose outputs from the pattern module call. [Gap] — **GAP-DEFERRED**: Acknowledged gap. Adding `outputs.tf` would expand scope (depends on root module outputs). Added to spec Out of Scope for follow-up.
- [x] CHK005 - Is a requirement defined for `.terraform.lock.hcl` handling? Should examples commit lock files for reproducibility or gitignore them? [Gap] — **RESOLVED**: `.terraform.lock.hcl` files in examples will be gitignored. Exact provider pins (FR-018) provide version reproducibility; lock file hash verification adds cross-platform friction without meaningful benefit. Added to spec edge cases.
- [x] CHK006 - ~~Are requirements specified for the naming module version pin in examples?~~ **SUPERSEDED**: Naming module removed from the pattern; naming is now the responsibility of pattern consumers. FR-007 updated accordingly. [Clarity, Spec §FR-007, §FR-018]

## Requirement Clarity

- [x] CHK007 - Is "all pattern module variables" in FR-017 quantified? The spec says 17+ variables but the exact count depends on FR-021 additions. Does "all" mean post-FR-021 or pre? [Ambiguity, Spec §FR-017, §FR-021] — **PASS**: "All" means the root module interface at implementation time. FR-021 expands type shapes (not variable count), so FR-017 naturally mirrors the post-FR-021 interface.
- [x] CHK008 - Is "multi-line heredoc format" in FR-020 defined with a concrete structure? The research.md shows a pattern but FR-020 itself does not specify the required fields per description (e.g., must it include AVM registry URL, field-by-field docs, or just a module reference?). [Clarity, Spec §FR-020] — **PASS**: FR-020 defines the requirement; research R5 provides the concrete template (summary, Uses/See lines, per-field bullets with AVM cross-refs). Spec FRs state _what_, plan artifacts define _how_.
- [x] CHK009 - Is "all user-configurable AVM module variables" in FR-021 scoped? The research audit identified high/medium/excluded priorities — does FR-021 require all high-priority, all medium, or everything? The term "all" is ambiguous. [Ambiguity, Spec §FR-021] — **RESOLVED**: Clarified FR-021 to reference R4 audit tiers (high + medium priority; intentionally excluded items documented in R4).
- [x] CHK010 - Is "deploy all mandatory dependent resources inline" in FR-005 defined per example? "Mandatory" is relative to each example's scenario — are the dependency sets specified or left to implementation judgment? [Clarity, Spec §FR-005] — **PASS**: Research R7 and data-model inline dependency model explicitly enumerate per-example deps. "Mandatory" is defined by each example's scenario scope (FR-011/012/013/016).
- [x] CHK011 - Are "defaults appropriate for that scenario" in FR-017 defined? What constitutes an "appropriate" default — must it pass validation, produce a meaningful plan, or both? [Clarity, Spec §FR-017] — **PASS**: Contract default strategy specifies: defaults must pass validation blocks; FR-006 requires terraform plan succeeds with no flags. "Appropriate" = passes validation + enables successful plan.

## Requirement Consistency

- [x] CHK012 - Are FR-001 and FR-009 consistent regarding the role of `terraform.tfvars`? FR-001 lists it as a required file; FR-009 defines it as the "primary value source." User Story 5 says `terraform plan` works with no flags — are defaults in `variables.tf` sufficient without tfvars, or is tfvars auto-loaded and therefore always active? [Consistency, Spec §FR-001, §FR-009, US5] — **PASS**: Consistent. Terraform auto-loads `terraform.tfvars`. FR-006 ensures defaults alone enable plan; FR-009's tfvars provides scenario overrides auto-loaded on top. Both paths work: defaults-only plan and tfvars-enhanced plan.
- [x] CHK013 - Is the `vwan/` to `vwan_hub/` rename consistently reflected? FR-013 says `examples/vwan_hub/` but User Story 1 scenarios, scope boundaries, and other references need to all use the same name. [Consistency, Spec §FR-013, §Scope] — **PASS**: All spec references use `vwan_hub/` consistently: US1-AS3, US4-AS3, FR-013, scope boundaries, clarifications.
- [x] CHK014 - Are FR-005 and FR-017 consistent on inline dependencies? FR-005 says "deploy all mandatory dependent resources inline using `azurerm_*` resource blocks," but FR-017 says "dependent resources MAY be hardcoded in `main.tf`." The "MAY" vs "MUST" distinction needs reconciliation. [Consistency, Spec §FR-005, §FR-017] — **PASS**: No conflict. FR-005 mandates that deps MUST exist inline. FR-017's "MAY be hardcoded" refers to how inline resource references are passed to the module call (hardcoded attribute refs vs variables). Different concerns: existence vs referencing mechanism.
- [x] CHK015 - Do User Story 4 acceptance scenarios align with the updated example set? US4-AS2 references `vnet_hub/` inline deps (RG, hub VNet, naming) — is this consistent with FR-016 scope? [Consistency, US4, §FR-016] — **PASS**: US4-AS2 and FR-016 are consistent — both specify hub VNet as the distinguishing inline dependency.

## Acceptance Criteria Quality

- [x] CHK016 - Can SC-005's file list be objectively verified? SC-005 lists `terraform.tf`, `main.tf`, `variables.tf`, `terraform.tfvars`, `_header.md` — but FR-019 also requires `README.md`. Should SC-005 include README.md? [Measurability, Spec §SC-005, §FR-019] — **RESOLVED**: Added `README.md` to SC-005 file list.
- [x] CHK017 - Is SC-001 testable for ALL four examples given that some require computed inline dependency references? If `variables.tf` defaults alone cannot produce a valid plan (e.g., `vnet_hub/` needs a hub VNet ID for peering), how does "no variable inputs" work? [Measurability, Spec §SC-001, §FR-006] — **PASS**: Inline deps are computed resource references in main.tf (not variable inputs). terraform.tfvars is auto-loaded. SC-001's "no variable inputs" means no -var/-var-file flags. All paths produce a valid plan.
- [x] CHK018 - Are success criteria defined for FR-020 (heredoc descriptions)? No SC verifies that root module variable descriptions meet the new format requirements. [Gap, Spec §FR-020] — **RESOLVED**: Added SC-007 for FR-020.
- [x] CHK019 - Are success criteria defined for FR-021 (AVM pass-through)? No SC verifies that the audit was performed and missing fields were added. [Gap, Spec §FR-021] — **RESOLVED**: Added SC-008 for FR-021.

## Scenario Coverage

- [x] CHK020 - Are requirements defined for what happens when an inline dependent resource fails to deploy? E.g., if the hub VNet in `vnet_hub/` fails, the pattern module call also fails — is this expected behavior or should there be a dependency chain? [Coverage, Exception Flow] — **PASS**: Standard Terraform behavior — implicit dependency graph handles this. No requirement needed; if a dep fails, the plan/apply fails naturally.
- [x] CHK021 - Are requirements specified for parallel deployment of multiple examples? FR-007 requires explicit unique names via `terraform.tfvars`, but are CIDR address space collisions between examples addressed? [Coverage, Spec §FR-007] — **PASS**: VNet CIDR ranges don't need to be globally unique — they only collide if peered. Each example deploys to separate RGs with independent VNets. Explicit names in tfvars ensure unique resource names. No collision risk.
- [x] CHK022 - Are requirements defined for the migration path from existing `examples/vwan/` to `examples/vwan_hub/`? Is this a rename, a fresh creation with the old directory deleted, or both kept? [Coverage, Gap] — **PASS**: Scope says "renamed to `examples/vwan_hub/`". Clarification says keep existing tfvars. Intent is clear: rename directory, preserve content, scaffold new files around it.

## Edge Case Coverage

- [x] CHK023 - Is the behavior specified when `terraform.tfvars` values conflict with `variables.tf` defaults? Terraform auto-loads `.tfvars` — are requirements clear that tfvars always overrides defaults? [Edge Case, Spec §FR-009] — **PASS**: Standard Terraform precedence — tfvars overrides variable defaults. FR-009 correctly describes tfvars as "overrides." No spec addition needed.
- [x] CHK024 - Are requirements defined for variables with validation blocks? If defaults must pass validation (FR-006 + FR-017), are all root module validation rules satisfiable with the example defaults? [Edge Case, Spec §FR-006, §FR-017] — **PASS**: Contract default strategy explicitly states "defaults must pass validation." FR-006 + FR-017 together mandate this. Implementation must verify at scaffold time.
- [x] CHK025 - Is the behavior specified for cross-variable validation preconditions in examples? The root module has `terraform_data.validation` with preconditions (e.g., LAW config required when LAW ID is null). Are example defaults guaranteed to satisfy these? [Edge Case, Gap] — **PASS**: Data-model shows minimal/vnet_hub/vwan_hub all override `log_analytics_workspace_configuration` (✅). Combined with FR-006 (plan must succeed) and SC-001, any precondition failure would be caught at validation time.

## Non-Functional Requirements

- [x] CHK026 - Are requirements defined for terraform-docs configuration per example? FR-019 mandates README.md but does not specify the terraform-docs output format (markdown table, markdown document) or config file (`.terraform-docs.yml`). [Gap, Spec §FR-019] — **PASS**: FR-019 defines the structure (_header.md + auto-docs); R6 specifies markers (BEGIN_TF_DOCS/END_TF_DOCS) and no footer. Sufficient for implementation — terraform-docs defaults produce markdown tables.
- [x] CHK027 - Are requirements specified for the order of AVM pass-through additions in FR-021 relative to example creation? Must root module changes land first (examples mirror the post-FR-021 interface) or can they be done in parallel? [Gap, Spec §FR-021, §FR-017] — **PASS**: Quickstart.md defines Phase A (root module changes) before Phase B (example scaffolding). Clear sequencing in plan artifact.

## Dependencies & Assumptions

- [x] CHK028 - Is the assumption that "the repository has been merged to main with the 001-spoke-shared-services feature complete" validated? If the branch is not yet merged, does implementation depend on this? [Assumption] — **PASS**: Feature 001 was fully implemented (45/45 tasks) and merged to main. Assumption validated.
- [x] CHK029 - Is the assumption about 17 root module variables still accurate post FR-021? FR-021 may ADD new variables or only expand existing types — the spec should clarify. [Assumption, Spec §FR-021] — **PASS**: FR-021 expands existing variable type shapes (adds fields like `role_assignments`, `lock` to existing objects). Does not add new top-level variables. Count remains 17.

## Traceability

- [x] CHK030 - Do all new FRs (FR-016–FR-021) have corresponding user stories or acceptance scenarios? FR-016 links to US4; FR-017–FR-019 link to US5/US1; FR-020 and FR-021 have no user story coverage. [Traceability, Gap] — **RESOLVED**: FR-020/FR-021 are root module enablers for the example variable interface. Linked to US5 as supporting requirements (better descriptions help consumers set variables correctly).

## Notes

- This checklist was generated against the post-plan-stage spec revision (21 FRs, 6 SCs, 4 examples).
- The existing `requirements.md` checklist (16/16 passed) covered pre-plan spec quality. This checklist targets the expanded spec with plan-stage additions (FR-016–FR-021, variables.tf pattern, 4 examples).
- Defaults applied: Depth=Standard, Audience=Reviewer, Focus=Combined (example scaffolding + root module changes).
