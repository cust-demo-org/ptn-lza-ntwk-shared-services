# Examples & Quickstart Checklist: ALZ Spoke Networking & Shared Services

**Purpose**: Validate that quickstart.md examples align with the current variable contracts, spec, and plan — especially after the CHK005 connectivity refactor and the subnet→NSG/RT reference direction fix.
**Created**: 2026-03-09
**Feature**: [spec.md](../spec.md)
**Depth**: Standard | **Audience**: Author self-review | **Scope**: Fresh independent pass

---

## Requirement Completeness — Minimal Example

- [x] CHK001 - Does the minimal example use the `peerings` map inside `virtual_networks` for hub connectivity instead of the removed `connectivity_mode` and `hub_virtual_network_id` variables? [Completeness, Quickstart §Minimal Example vs Contracts §Connectivity Variables Design Note]
- [x] CHK002 - Does the minimal example demonstrate all required fields in the `peerings` map entry (`name`, `remote_virtual_network_resource_id`) per the variable contract? [Completeness, Quickstart §Minimal Example vs Contracts §virtual_networks.peerings]
- [x] CHK003 - Are optional peering fields (`allow_forwarded_traffic`, `create_reverse_peering`, etc.) shown with their defaults documented in inline comments? [Clarity, Spec §FR-031]
- [x] CHK004 - Does the minimal example show that `network_security_group_key` and `route_table_key` are optional fields on subnets (not required), consistent with the contract's `optional(string)` type? [Clarity, Contracts §virtual_networks.subnets]

## Requirement Completeness — Private DNS Zone Links Example

- [x] CHK005 - Does the Private DNS Zone links example include the required `virtual_network_key` field per the variable contract? [Completeness, Quickstart §Adding Private DNS Zone Links vs Contracts §private_dns_zone_links]
- [x] CHK006 - Does the example show the `resolution_policy` optional field or document its default (`"Default"`) in an inline comment? [Clarity, Contracts §private_dns_zone_links]
- [x] CHK007 - Does the example show per-link `tags` or document that they are optional and merge with common tags? [Clarity, Contracts §private_dns_zone_links]

## Requirement Completeness — vWAN Connectivity Example

- [x] CHK008 - Does the vWAN example use `vhub_connectivity_definitions` map instead of the removed `connectivity_mode = "vwan"` and `virtual_hub_id` variables? [Completeness, Quickstart §Switching to vWAN Connectivity vs Contracts §vhub_connectivity_definitions]
- [x] CHK009 - Does the vWAN example demonstrate the required fields (`vhub_resource_id`, `virtual_network.key` or `virtual_network.id`) per the variable contract? [Completeness, Contracts §vhub_connectivity_definitions]
- [x] CHK010 - Does the vWAN example document the `internet_security_enabled` default (`true`) and explain its security implication (routes internet traffic through hub firewall)? [Clarity, Spec §FR-013 / Research §10]

## Requirement Completeness — Key Vault Example

- [x] CHK011 - Does the Key Vault role assignment example use the flat `managed_identity_key` string field instead of the nested `principal_id_reference` object? [Completeness, Quickstart §Adding Key Vault with Managed Identity vs Contracts §key_vaults.role_assignments]
- [x] CHK012 - Does the Key Vault example show the `role_definition_id_or_name` and `managed_identity_key` fields matching the variable contract shape exactly? [Clarity, Contracts §key_vaults.role_assignments]

## Requirement Completeness — Bastion Example

- [x] CHK013 - Does the Bastion example's `AzureBastionSubnet` intentionally omit `network_security_group_key` and `route_table_key`, and is this omission explained (Bastion manages its own NSG)? [Clarity, Quickstart §Enabling Azure Bastion vs Spec §FR-007]
- [x] CHK014 - Does the Bastion example show all required fields in `bastion_configuration` per the variable contract (`virtual_network_key`, `resource_group_key`)? [Completeness, Contracts §bastion_configuration]

## Requirement Consistency — Cross-Example Alignment

- [x] CHK015 - Are all variable names used in quickstart.md examples consistent with the actual variable names in contracts/variables.md (no renamed/removed variables remain)? [Consistency, Quickstart vs Contracts]
- [x] CHK016 - Are all object field names in quickstart.md examples consistent with the actual field names in contracts/variables.md type definitions? [Consistency, Quickstart vs Contracts]
- [x] CHK017 - Do the examples use `set(string)` syntax for `address_space` (e.g., `["10.1.0.0/16"]`) consistent with the variable type definition? [Consistency, Contracts §virtual_networks.address_space]

## Requirement Consistency — Prerequisites Section

- [x] CHK018 - Does the Prerequisites section align with the current spec assumptions (state backend locking assumption was removed in CHK035)? [Consistency, Quickstart §Prerequisites vs Spec §Assumptions]
- [x] CHK019 - Does the Prerequisites section mention Terraform CLI `>= 1.13` consistent with the spec's version constraint (`>= 1.13, < 2.0`)? [Consistency, Quickstart §Prerequisites vs Spec §Assumptions]

## Scenario Coverage — Missing Examples

- [x] CHK020 - Is there an example scenario showing a spoke VNet with **no connectivity** (no peering, no vWAN) — the isolated VNet edge case documented in the spec? [Coverage, Spec §Edge Cases / Clarifications §connectivity]
- [x] CHK021 - Is there an example scenario showing standalone role assignments via the `role_assignments` variable? [Coverage, Contracts §role_assignments / Spec §US3]
- [x] CHK022 - Is there an example showing the `log_analytics_workspace_id` variable to use an existing workspace (vs auto-create)? [Coverage, Contracts §log_analytics_workspace_id / Spec §FR-028]
- [x] CHK023 - Is there an example showing `use_random_suffix = true` for globally-unique resource names? [Coverage, Contracts §use_random_suffix / Spec §FR-025]
- [x] CHK024 - Is there an example showing the `lock` variable for resource locks? [Coverage, Contracts §lock / Spec §Research §7]

## Scenario Coverage — Plan Project Structure

- [x] CHK025 - Does the quickstart reference `examples/minimal/terraform.tfvars` for copy — and does the minimal example content in quickstart.md match the plan's description of the `examples/minimal/` folder ("Minimal spoke VNet with hub peering (US1)")? [Consistency, Quickstart §Step 2 vs Plan §Project Structure]
- [x] CHK026 - Does the plan's `examples/vwan/terraform.tfvars` description ("vWAN connectivity via vhub_connectivity_definitions (US4)") align with the vWAN example in quickstart.md? [Consistency, Plan §Project Structure vs Quickstart §Switching to vWAN]

## Edge Case Coverage

- [x] CHK027 - Does the minimal example show what happens when `security_rules = {}` (empty map) — is it clear that only Azure built-in default rules apply and no rules are auto-injected? [Edge Case, Quickstart §NSG nsg-data vs Spec §FR-008 / Contracts §network_security_groups.description]
- [x] CHK028 - Does the Bastion example address the `AzureBastionSubnet` CIDR size requirement (`/26` minimum) in an inline comment? [Edge Case, Quickstart §Enabling Azure Bastion]

## Acceptance Criteria Quality

- [x] CHK029 - Does the quickstart's "Verify" checklist (Step 4) align with measurable success criteria from the spec (SC-001 through SC-008)? [Acceptance Criteria, Quickstart §Step 4 vs Spec §Success Criteria]
- [x] CHK030 - Does Step 6 "Verify Idempotency" directly map to SC-002 ("zero resource changes")? [Acceptance Criteria, Quickstart §Step 6 vs Spec §SC-002]

## Notes

- Check items off as completed: `[x]`
- This checklist targets quickstart.md and example correctness after the CHK005 connectivity refactor and the subnet→NSG/RT reference direction fix
- Items CHK001, CHK005, CHK008, CHK011 are high-priority — they catch stale examples using removed variables
