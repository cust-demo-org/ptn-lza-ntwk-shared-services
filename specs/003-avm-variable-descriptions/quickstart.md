# Quickstart: AVM-Style Variable Description Rewrite

**Feature**: 003-avm-variable-descriptions  
**Date**: 2026-03-17

---

## Prerequisites

1. Branch `003-avm-variable-descriptions` checked out
2. `.terraform/modules/` populated via `terraform init` in `examples/full/`
3. `terraform-docs` available at: `C:\Users\minheinaung\AppData\Local\Microsoft\WinGet\Packages\Terraform-docs.Terraform-docs_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform-docs.exe`

---

## Implementation Workflow

### Step 1: Establish the template with `resource_groups` (simplest complex variable)

1. Read AVM source: `examples/full/.terraform/modules/resource_group/variables.tf`
2. Rewrite `resource_groups` description in root `variables.tf` (L23-L57)
3. Follow the Description Style Contract (`contracts/description-style.md`)
4. Run `terraform validate` on root module
5. Run `terraform-docs .` and inspect rendering

### Step 2: Apply to remaining variables in priority order

Work through variables in the order from `data-model.md` § Description Rewrite Priority Order:
- Trivial: `location`, `tags` (light polish only)
- Low: `byo_log_analytics_workspace`, `byo_private_dns_zone_links`, `route_tables`, `role_assignments`
- Medium: `network_security_groups`, `private_dns_zones`, `managed_identities`, `vhub_connectivity_definitions`, `bastion_hosts`, `flowlog_configuration`
- High: `log_analytics_workspace_configuration`, `key_vaults`
- Very High: `virtual_networks`, `storage_accounts`

### Step 3: For each variable, follow this checklist

- [ ] Read the AVM module's variable description from `.terraform/modules/<module>/variables.tf`
- [ ] Copy AVM text verbatim for matching attributes (FR-003)
- [ ] Fix any known copy-paste bugs (research.md §6)
- [ ] Add `(Required)`/`(Optional)` markers to every leaf attribute (FR-002)
- [ ] Add "deliberately arbitrary" statement for `map(object)` types (FR-004)
- [ ] Document standard interface blocks using contract templates: `lock` (§3a), `role_assignments` (§3b/3c), `diagnostic_settings` (§3d), `private_endpoints` (§3e)
- [ ] Add cross-reference key documentation for pattern keys like `resource_group_key` (FR-016)
- [ ] Add pattern-specific notes in `> **Pattern note:**` callout format (FR-009)
- [ ] Document mutual exclusivity with both inline + `> Note:` callout (FR-017)
- [ ] Remove any `Uses:` / `See:` lines (FR-001)
- [ ] Verify description does NOT change type, default, or validation (FR-010)

### Step 4: Validate after each variable

```powershell
# From repo root:
terraform validate

# From each example:
cd examples/minimal; terraform validate; cd ../..
cd examples/vnet_hub; terraform validate; cd ../..
cd examples/vwan_hub; terraform validate; cd ../..
cd examples/full; terraform validate; cd ../..
```

### Step 5: After all 17 variables complete

```powershell
# Regenerate all READMEs
& "C:\Users\minheinaung\AppData\Local\Microsoft\WinGet\Packages\Terraform-docs.Terraform-docs_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform-docs.exe" .
cd examples/minimal; & "C:\Users\minheinaung\AppData\Local\Microsoft\WinGet\Packages\Terraform-docs.Terraform-docs_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform-docs.exe" .; cd ../..
cd examples/vnet_hub; & "C:\Users\minheinaung\AppData\Local\Microsoft\WinGet\Packages\Terraform-docs.Terraform-docs_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform-docs.exe" .; cd ../..
cd examples/vwan_hub; & "C:\Users\minheinaung\AppData\Local\Microsoft\WinGet\Packages\Terraform-docs.Terraform-docs_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform-docs.exe" .; cd ../..
cd examples/full; & "C:\Users\minheinaung\AppData\Local\Microsoft\WinGet\Packages\Terraform-docs.Terraform-docs_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform-docs.exe" .; cd ../..
```

### Step 6: Final verification

- [ ] SC-001: All 17 variables rewritten
- [ ] SC-002: 100% nested attributes documented (grep for "See AVM module" — should find 0)
- [ ] SC-003: README is self-sufficient for tfvars authoring
- [ ] SC-004: terraform-docs output has no rendering artifacts
- [ ] SC-005: `terraform validate` passes on root + 4 examples
- [ ] SC-006: Every `map(object)` has "deliberately arbitrary" statement

---

## Key References

| Reference | Path |
|-----------|------|
| Feature spec | `specs/003-avm-variable-descriptions/spec.md` |
| Research findings | `specs/003-avm-variable-descriptions/research.md` |
| Variable-module mapping | `specs/003-avm-variable-descriptions/data-model.md` |
| Description style contract | `specs/003-avm-variable-descriptions/contracts/description-style.md` |
| Root variables.tf | `variables.tf` (17 variables, ~1510 lines) |
| AVM module sources | `examples/full/.terraform/modules/` |

---

## Common Pitfalls (from Feature 002 Lessons)

1. **Don't change types or defaults** — only the `description` attribute (FR-010, L1)
2. **Don't paraphrase AVM text** — copy verbatim, then append pattern notes (FR-003, L3)
3. **Run terraform validate frequently** — after every variable, not just at the end (L5)
4. **Check terraform-docs rendering** — backtick escaping in heredocs can break (L4)
5. **managed_identity role_assignments is different** — uses `scope`, not `principal_id` (research.md §8)
6. **Storage account has 6 AVM source files** — check all of them (research.md §7)
