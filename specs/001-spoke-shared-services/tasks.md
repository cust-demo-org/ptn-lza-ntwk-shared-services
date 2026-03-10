# Tasks: ALZ Spoke Networking & Shared Services Pattern

**Input**: Design documents from `/specs/001-spoke-shared-services/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not requested — quality gates only (fmt, validate, plan, tflint, terraform-docs).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create project skeleton and tooling configuration

- [ ] T001 Create version constraints and provider requirements in terraform.tf — declare `required_version = ">= 1.13, < 2.0"` and `required_providers` block for azurerm (`~> 4.0`), azapi (`~> 2.0`), and random (`~> 3.0`); include source registry paths per plan.md §Technical Context
- [ ] T002 [P] Create terraform-docs configuration in .terraform-docs.yml — configure markdown table output format, sort by required/type, enable README.md injection between `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers
- [ ] T003 [P] Create tflint configuration in .tflint.hcl — enable the azurerm ruleset plugin with recommended rules
- [ ] T004 [P] Create README.md with pattern overview and `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` injection markers per FR-034

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core variables, modules, locals, and outputs that ALL user stories depend on — resource groups, naming module, Log Analytics workspace, and global configuration.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T005 Create variables.tf with global variables: `location` (string, required), `tags` (map(string), default `{}`), `use_random_suffix` (bool, default `false`), `lock` (object with kind/name, default `null` with validation), `resource_groups` (map of objects per contracts/variables.md §resource_groups), `log_analytics_workspace_id` (string, default `null`), and `log_analytics_workspace_configuration` (object, default `null`) — all per contracts/variables.md
- [ ] T006 Create main.tf with three module blocks: (1) `naming` module (`Azure/naming/azurerm` v0.4.3) passing `var.location` and suffix config, (2) `resource_group` module (`Azure/avm-res-resources-resourcegroup/azurerm` v0.2.2) with `for_each = var.resource_groups` passing name, location (defaulting to `var.location`), tags (merged with `var.tags`), and `var.lock`, (3) conditional `log_analytics_workspace` module (`Azure/avm-res-operationalinsights-workspace/azurerm` v0.5.1) created only when `var.log_analytics_workspace_id == null`, with `for_each` or `count` conditional pattern, passing name, location, resource_group_name (resolved from resource_group_key), sku, retention, tags, and `var.lock`
- [ ] T007 Create locals.tf with computed values: (1) `log_analytics_workspace_id` — coalesce `var.log_analytics_workspace_id` with auto-created workspace resource ID, (2) `diagnostic_settings_default` — reusable diagnostic settings map pointing to `local.log_analytics_workspace_id`, (3) resource group name lookup map for resolving `resource_group_key` → `module.resource_group[key].name`
- [ ] T008 Create outputs.tf with `resource_groups` output (map of keys → {resource_id, name} from module.resource_group) and `log_analytics_workspace` output ({resource_id, name} using local.log_analytics_workspace_id) per contracts/outputs.md
- [ ] T009 Run `terraform init`, `terraform fmt -check -recursive`, and `terraform validate` to confirm foundational setup compiles

**Checkpoint**: Foundation ready — user story implementation can now begin.

---

## Phase 3: User Story 1 — Deploy a Minimal Spoke VNet with Peering to Hub (Priority: P1) 🎯 MVP

**Goal**: A platform engineer deploys a spoke VNet with subnets, NSGs, route tables, hub peering, and diagnostic settings by editing only `terraform.tfvars`.

**Independent Test**: Deploy a spoke VNet with one subnet peered to a hub VNet. Run `terraform plan` and verify VNet, subnet, NSG, route table, peering, and diagnostic settings are created. Run `terraform plan` again — zero changes (SC-002).

### Implementation for User Story 1

- [ ] T010 [US1] Add `network_security_groups` variable to variables.tf per contracts/variables.md §network_security_groups — map of objects with name, resource_group_key, location (optional), security_rules (optional map of rule objects, default `{}`), and tags (optional)
- [ ] T011 [US1] Add `route_tables` variable to variables.tf per contracts/variables.md §route_tables — map of objects with name, resource_group_key, location (optional), bgp_route_propagation_enabled (optional bool, default `true`), routes (optional map of route objects), and tags (optional)
- [ ] T012 [US1] Add `virtual_networks` variable to variables.tf per contracts/variables.md §virtual_networks — map of objects with name, address_space, resource_group_key, location, dns_servers, ddos_protection_plan, encryption, tags, peerings (optional map per AVM VNet module interface), and subnets (optional map with name, address_prefix/address_prefixes, network_security_group_key, route_table_key, service_endpoints, delegations, and all fields from contracts/variables.md)
- [ ] T013 [US1] Add NSG for_each module block (`Azure/avm-res-network-networksecuritygroup/azurerm` v0.5.1) to main.tf — iterate over `var.network_security_groups`, pass name, resource_group_name (resolved from resource_group_key), location (default `var.location`), security_rules, diagnostic_settings (using `local.diagnostic_settings_default`), `var.lock`, and merged tags
- [ ] T014 [US1] Add route table for_each module block (`Azure/avm-res-network-routetable/azurerm` v0.5.0) to main.tf — iterate over `var.route_tables`, pass name, resource_group_name, location, bgp_route_propagation_enabled, routes, `var.lock`, and merged tags
- [ ] T015 [US1] Add NSG and route table ID resolution locals to locals.tf — create lookup maps: `nsg_resource_ids` (map of NSG key → `module.network_security_group[key].resource_id`) and `rt_resource_ids` (map of RT key → `module.route_table[key].resource_id`) for use in subnet associations
- [ ] T016 [US1] Add virtual_networks for_each module block (`Azure/avm-res-network-virtualnetwork/azurerm` v0.17.1) to main.tf — iterate over `var.virtual_networks`, pass name, address_space, resource_group_name (resolved from resource_group_key), location, dns_servers, subnets (with computed `network_security_group = { id = local.nsg_resource_ids[subnet.network_security_group_key] }` and `route_table = { id = local.rt_resource_ids[subnet.route_table_key] }` when keys are provided), peerings (passed through directly from input), diagnostic_settings, `var.lock`, and merged tags
- [ ] T017 [P] [US1] Add `network_security_groups`, `route_tables`, and `virtual_networks` outputs to outputs.tf per contracts/outputs.md — each as a for expression mapping keys to {resource_id, name} (virtual_networks also includes address_spaces, subnets, peerings)
- [ ] T018 [P] [US1] Create examples/minimal/terraform.tfvars with a minimal spoke VNet and hub peering example matching quickstart.md §Minimal Example — include one VNet with two subnets, one NSG with an allow-HTTPS rule, one NSG with empty security_rules, one route table with default-to-firewall route, and one hub peering entry

**Checkpoint**: User Story 1 complete — spoke VNet with NSGs, route tables, peering, and diagnostics is deployable.

---

## Phase 4: User Story 2 — Add Private DNS Zone Links to Spoke (Priority: P2)

**Goal**: A platform engineer links existing Private DNS Zones to the spoke VNet for private endpoint resolution.

**Independent Test**: Deploy a spoke VNet (from US1) and add DNS zone links. Verify VNet links exist in each DNS zone.

### Implementation for User Story 2

- [ ] T019 [US2] Add `private_dns_zone_links` variable to variables.tf per contracts/variables.md §private_dns_zone_links — map of objects with private_dns_zone_id (string), virtual_network_key (string), registration_enabled (optional bool, default `false`), resolution_policy (optional string, default `"Default"`), and tags (optional)
- [ ] T020 [US2] Add private_dns_zone_links for_each module block to main.tf using AVM submodule `Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link` v0.5.0 — iterate over `var.private_dns_zone_links`, pass parent_id (from private_dns_zone_id), name (computed as `dnslink-{domain}-{vnet-name}` per data-model.md §Private DNS Zone Link), virtual_network_id (resolved from virtual_network_key via `module.virtual_network[link.virtual_network_key].resource_id`), registration_enabled, resolution_policy, and tags
- [ ] T021 [P] [US2] Add `private_dns_zone_links` output to outputs.tf per contracts/outputs.md — map of keys → {resource_id, name}

**Checkpoint**: User Story 2 complete — DNS zone VNet links are deployable alongside US1.

---

## Phase 5: User Story 3 — Deploy Shared Key Vault with Managed Identities (Priority: P3)

**Goal**: A platform engineer provisions Key Vaults, managed identities, and RBAC role assignments via `terraform.tfvars`.

**Independent Test**: Deploy a Key Vault with a managed identity and role assignment. Verify Key Vault has public access disabled, managed identity exists, and role assignment is scoped correctly.

### Implementation for User Story 3

- [ ] T022 [US3] Add `managed_identities` variable to variables.tf per contracts/variables.md §managed_identities — map of objects with name, resource_group_key, location (optional), and tags (optional)
- [ ] T023 [US3] Add `key_vaults` variable to variables.tf per contracts/variables.md §key_vaults — map of objects with name, resource_group_key, location, sku_name (default `"premium"`), public_network_access_enabled (default `false`), purge_protection_enabled (default `true`), network_acls (default `{default_action = "Deny"}`), role_assignments (with principal_id and managed_identity_key — exactly one required), private_endpoints, and tags
- [ ] T024 [US3] Add `role_assignments` variable to variables.tf per contracts/variables.md §role_assignments — map of objects with role_definition_id_or_name, scope, principal_id (optional), managed_identity_key (optional), description, and principal_type; add description documenting the two principal reference modes
- [ ] T025 [US3] Add managed_identities for_each module block (`Azure/avm-res-managedidentity-userassignedidentity/azurerm` v0.4.0) to main.tf — iterate over `var.managed_identities`, pass name, location (default `var.location`), resource_group_name (resolved from resource_group_key), `var.lock`, and merged tags
- [ ] T026 [US3] Add managed identity principal_id resolution local to locals.tf — create `managed_identity_principal_ids` map (MI key → `module.managed_identity[key].principal_id`) for use in Key Vault role assignments and standalone role assignments
- [ ] T027 [US3] Add key_vaults for_each module block (`Azure/avm-res-keyvault-vault/azurerm` v0.10.2) to main.tf — iterate over `var.key_vaults`, pass name, resource_group_name, location, sku_name, public_network_access_enabled, purge_protection_enabled, network_acls, role_assignments (resolving managed_identity_key → principal_id via `local.managed_identity_principal_ids[ra.managed_identity_key]` when set, otherwise using ra.principal_id directly), diagnostic_settings, `var.lock`, private_endpoints, and merged tags
- [ ] T028 [US3] Add standalone role_assignments for_each module block (`Azure/avm-res-authorization-roleassignment/azurerm` v0.3.0) to main.tf — iterate over `var.role_assignments`, pass role_definition_id_or_name, scope, principal_id (resolved from managed_identity_key or direct principal_id), description, and principal_type
- [ ] T029 [P] [US3] Add `managed_identities`, `key_vaults`, and `role_assignments` outputs to outputs.tf per contracts/outputs.md — managed_identities: {resource_id, name, principal_id, client_id}; key_vaults: {resource_id, name, uri}; role_assignments: {resource_id} (empty map when none configured)

**Checkpoint**: User Story 3 complete — Key Vaults with managed identities and RBAC are deployable.

---

## Phase 6: User Story 4 — Deploy Spoke Connected to Virtual WAN Hub (Priority: P4)

**Goal**: A platform engineer connects a spoke VNet to a vWAN hub instead of (or in addition to) hub VNet peering.

**Independent Test**: Deploy a spoke VNet with a vWAN hub connection. Verify the Virtual Hub VNet connection exists with internet_security_enabled.

### Implementation for User Story 4

- [ ] T030 [US4] Add `vhub_connectivity_definitions` variable with mutual exclusivity validation rule to variables.tf per contracts/variables.md §vhub_connectivity_definitions — map of objects with vhub_resource_id (string), virtual_network (object with key and id — exactly one required), and internet_security_enabled (optional bool, default `true`); include the `alltrue` validation ensuring `(key != null) != (id != null)`
- [ ] T031 [US4] Add VNet reference resolution local for vhub connections to locals.tf — create a computed map resolving each `vhub_connectivity_definitions` entry's `virtual_network.key` to `module.virtual_network[key].resource_id`, or passing through `virtual_network.id` directly
- [ ] T032 [US4] Add vhub_connectivity_definitions for_each module block to main.tf using AVM submodule `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection` v0.13.5 — iterate over `var.vhub_connectivity_definitions`, pass virtual_network_connections map with name (computed), virtual_hub_id (from vhub_resource_id), remote_virtual_network_id (resolved from local), internet_security_enabled, and routing (if provided)
- [ ] T033 [P] [US4] Add `vhub_connections` output to outputs.tf per contracts/outputs.md — map of keys → {resource_id}
- [ ] T034 [P] [US4] Create examples/vwan/terraform.tfvars with vWAN connectivity example matching quickstart.md §Switching to vWAN Connectivity — include a spoke VNet with vhub_connectivity_definitions entry

**Checkpoint**: User Story 4 complete — vWAN hub connections are deployable alongside or instead of hub peering.

---

## Phase 7: User Story 5 — Deploy Azure Bastion for Spoke Access (Priority: P5)

**Goal**: A platform engineer enables Azure Bastion for secure remote access by setting `enable_bastion = true`.

**Independent Test**: Deploy a spoke VNet with Bastion enabled. Verify AzureBastionSubnet, Bastion host, and diagnostic settings exist.

### Implementation for User Story 5

- [ ] T035 [US5] Add `enable_bastion` (bool, default `false`) and `bastion_configuration` (object with name, virtual_network_key, resource_group_key, sku default `"Standard"`, location, zones default `["1","2","3"]`, tags) variables to variables.tf per contracts/variables.md §Bastion Variables
- [ ] T036 [US5] Add conditional bastion_host module block (`Azure/avm-res-network-bastionhost/azurerm` v0.9.0) to main.tf — conditional on `var.enable_bastion`, pass name, location, resource_group_name (resolved from resource_group_key), virtual_network_id (resolved from virtual_network_key), sku, zones, diagnostic_settings, `var.lock`, and merged tags; add precondition verifying VNet contains an `AzureBastionSubnet`
- [ ] T037 [P] [US5] Add `bastion` output to outputs.tf per contracts/outputs.md — {resource_id, name} when enabled, `null` when disabled

**Checkpoint**: User Story 5 complete — Bastion is deployable as an optional add-on.

---

## Phase 8: Network Watcher & Flow Logs (Cross-Cutting, Optional)

**Purpose**: Optional Network Watcher VNet flow log configuration via AVM module.

**⚠️ NOTE**: This phase is entirely optional. Skip if `flowlog_configuration` is not required.

### Implementation for Network Watcher

- [ ] T043 Add `flowlog_configuration` variable to variables.tf per contracts/variables.md §Network Watcher Variables — object with network_watcher_id, network_watcher_name, resource_group_name, location, flow_logs map, and tags; default `null` (implicit toggle — null = no flow logs)
- [ ] T044 Add conditional network_watcher module block (`Azure/avm-res-network-networkwatcher/azurerm` v0.3.2) to main.tf — conditional on `var.flowlog_configuration != null` (use `count = var.flowlog_configuration != null ? 1 : 0`), pass network_watcher_id, network_watcher_name, resource_group_name, location, flow_logs (passed through from var.flowlog_configuration.flow_logs), `var.lock`, and merged tags
- [ ] T045 [P] Add `network_watcher` output to outputs.tf per contracts/outputs.md — {resource_id, flow_logs} when configured, `null` when disabled

**Checkpoint**: Network Watcher flow logs configurable as an optional add-on.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Validation rules, example files, documentation, and quality gates.

- [ ] T038 Add cross-variable validation preconditions to module blocks in main.tf — (1) Key Vault role_assignments: exactly one of principal_id or managed_identity_key set, and managed_identity_key exists in var.managed_identities, (2) private_dns_zone_links: virtual_network_key exists in var.virtual_networks, (3) bastion: enable_bastion requires bastion_configuration non-null, (4) subnets: each address_prefix XOR address_prefixes set (per contracts/variables.md §Validation Rules Summary), (5) log_analytics_workspace_configuration must be non-null when log_analytics_workspace_id is null (FR-028), (6) standalone role_assignments: exactly one of principal_id or managed_identity_key set, and managed_identity_key exists in var.managed_identities
- [ ] T039 [P] Create terraform.tfvars with rich inline comments for all variables — document each variable's purpose, type, object shape, defaults, and security implications per FR-031
- [ ] T040 [P] Create examples/full/terraform.tfvars with all features enabled (all user stories) — resource groups, VNet with subnets/NSGs/route tables/peering, DNS zone links, managed identities, Key Vault with role assignments, vWAN connection, Bastion, flowlog_configuration, resource locks, random suffix
- [ ] T041 Run all quality gates: `terraform fmt -check -recursive`, `terraform validate`, `terraform plan` (against a CI subscription or mock backend), `tflint --init && tflint` per FR-036/FR-037. Verify no public IP resources appear in the plan output unless enable_bastion = true (SC-003).
- [ ] T042 [P] Run `terraform-docs markdown table . --output-file README.md` to generate input/output documentation between injection markers per FR-033/FR-035

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) — **BLOCKS all user stories**
- **User Stories (Phases 3–7)**: All depend on Foundational (Phase 2)
  - US1 (P1): Can start immediately after Phase 2
  - US2 (P2): Depends on US1 (needs virtual_networks module for VNet ID resolution)
  - US3 (P3): **Independent of US1** — can start in parallel with US1 after Phase 2
  - US4 (P4): Depends on US1 (needs virtual_networks module for VNet ID resolution)
  - US5 (P5): Depends on US1 (needs virtual_networks module for AzureBastionSubnet)
- **Polish (Phase 9)**: Depends on all user stories and Network Watcher phase being complete

### User Story Dependencies

```
Phase 1 (Setup)
    │
Phase 2 (Foundational)
    │
    ├── US1 (P1) ──────────┬── US2 (P2)
    │                       ├── US4 (P4)
    │                       └── US5 (P5)
    │
    └── US3 (P3) ← independent of US1, can run in parallel
    │
Phase 8 (Network Watcher) ← optional, depends on Phase 2
    │
Phase 9 (Polish)
```

### Within Each User Story

1. Variables (variables.tf) first
2. Module blocks (main.tf) — depends on variables
3. Locals (locals.tf) — depends on module block names for resource references
4. Outputs (outputs.tf) — depends on module block names; marked [P] when independent of main.tf edits
5. Example tfvars (examples/) — marked [P], new file with no code dependencies

### Parallel Opportunities

**Phase 1**: T002, T003, T004 can run in parallel (different files)

**After Phase 2**: US1 and US3 can run in parallel (US3 needs only resource groups, not VNets)

**Within US1**: T017 (outputs.tf) and T018 (examples/minimal/terraform.tfvars) can run together

**Within US4**: T033 (outputs.tf) and T034 (examples/vwan/terraform.tfvars) can run together

**Phase 8**: T045 can run in parallel with T044 (different files)

**Phase 9**: T039, T040, T042 can run in parallel (different files)

---

## Parallel Example: Phase 1

```
# All three can run simultaneously (different files):
Task T002: Create terraform-docs configuration in .terraform-docs.yml
Task T003: Create tflint configuration in .tflint.hcl
Task T004: Create README.md with pattern overview and terraform-docs markers
```

## Parallel Example: User Stories 1 + 3

```
# After Phase 2, these two stories can proceed in parallel:

# Developer A: US1 (networking)
Task T010: Add network_security_groups variable to variables.tf
Task T011: Add route_tables variable to variables.tf
...

# Developer B: US3 (Key Vault + managed identities)
Task T022: Add managed_identities variable to variables.tf
Task T023: Add key_vaults variable to variables.tf
...

# Note: Both edit variables.tf/main.tf — coordinate via separate sections or merge after
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (4 tasks)
2. Complete Phase 2: Foundational (5 tasks)
3. Complete Phase 3: User Story 1 (9 tasks)
4. **STOP and VALIDATE**: Run `terraform plan` — verify VNet, subnets, NSGs, route tables, peering, diagnostics
5. Run `terraform plan` again — verify zero changes (SC-002)
6. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (Spoke VNet + Peering) → Validate → **MVP!** (18 tasks)
3. Add US2 (DNS Zone Links) → Validate → Deploy (21 tasks)
4. Add US3 (Key Vault + MI) → Validate → Deploy (29 tasks)
5. Add US4 (vWAN) → Validate → Deploy (34 tasks)
6. Add US5 (Bastion) → Validate → Deploy (37 tasks)
7. Add Network Watcher (optional) → Validate → Deploy (40 tasks)
8. Polish → Final quality gates (45 tasks)

### Parallel Team Strategy

With two developers:

1. Team completes Setup + Foundational together
2. Once Foundational completes:
   - **Developer A**: US1 (networking) → US2 (DNS) → US4 (vWAN) → US5 (Bastion) → Network Watcher
   - **Developer B**: US3 (Key Vault + MI) → Polish tasks
3. Merge and run final quality gates

---

## Notes

- **[P]** tasks target different files with no dependencies — safe to parallelize
- **[Story]** label maps tasks to specific user stories for traceability
- All module version pins are exact (e.g., v0.5.1 not ~> 0.5) per FR-003
- All AVM module interface fields (diagnostic_settings, lock, role_assignments, tags) are passed through consistently per plan.md §AVM Module Interface Summary
- `var.lock` is passed to all AVM root-module resources but NOT submodule resources (DNS links, vHub connections) per contracts/variables.md §lock description
- `local.diagnostic_settings_default` is passed to all resources that support it, EXCEPT the auto-created Log Analytics workspace (exempt from self-diagnostics per FR-027)
- Network Watcher (Phase 8) is entirely optional — skip if `flowlog_configuration` is not needed. The module uses `count` conditional, not `for_each`, since only one Network Watcher per configuration is expected
- Commit after each task or logical group
- Stop at any checkpoint to validate the story independently
