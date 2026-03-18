# Data Model: Variable-to-AVM Module Mapping

**Feature**: 003-avm-variable-descriptions  
**Date**: 2026-03-17

---

## Variable Inventory

17 variables in root `variables.tf` (~1510 lines). Each variable maps to one or more AVM modules.

### Simple Scalars (FR-018: light polish only)

| # | Variable | Line | Type | AVM Module | Nested Attrs |
|---|----------|------|------|------------|-------------|
| 1 | `location` | L1 | `string` | N/A (pattern-level) | 0 |
| 2 | `tags` | L10 | `map(string)` | N/A (pattern-level) | 0 |

### Complex Objects (Full AVM bullet-list rewrite)

| # | Variable | Line | Type | AVM Module(s) | Est. Leaf Attrs |
|---|----------|------|------|---------------|-----------------|
| 3 | `resource_groups` | L23 | `map(object)` | resource_group v0.2.2 | ~5 (lock, role_assignments, tags) |
| 4 | `byo_log_analytics_workspace` | L58 | `object` | N/A (pattern cross-ref) | ~2 (resource_id, workspace_id) |
| 5 | `log_analytics_workspace_configuration` | L71 | `object` | log_analytics_workspace v0.5.1 | ~45 (identity, CMK, data_exports, tables, linked_storage, diag, PE, lock, role_assignments) |
| 6 | `network_security_groups` | L211 | `map(object)` | NSG v0.5.1 | ~18 (security_rules, diag, lock, role_assignments, resource_group_key) |
| 7 | `route_tables` | L287 | `map(object)` | route_table v0.5.0 | ~12 (routes, lock, role_assignments, resource_group_key) |
| 8 | `virtual_networks` | L333 | `map(object)` | virtual_network v0.17.1 | ~55 (subnets, peerings, diag, lock, role_assignments, dns_servers) |
| 9 | `private_dns_zones` | L511 | `map(object)` | private_dns_zone v0.5.0 + link submodule | ~15 (virtual_network_links, lock, role_assignments) |
| 10 | `byo_private_dns_zone_links` | L562 | `map(object)` | private_dns_zone_link submodule v0.5.0 | ~5 (zone_key, vnet_key, registration_enabled) |
| 11 | `managed_identities` | L591 | `map(object)` | managed_identity v0.4.0 | ~12 (lock, role_assignments w/scope, federated_identity_credentials) |
| 12 | `key_vaults` | L634 | `map(object)` | key_vault v0.10.2 | ~50 (contacts, keys, secrets, PE, diag, lock, role_assignments, network_acls) |
| 13 | `role_assignments` | L821 | `map(object)` | role_assignment v0.3.0 | ~6 (scope, role_definition, principal_id/managed_identity_key, description, principal_type) |  

> **WARNING**: The standalone `role_assignments` variable (L821) is NOT the same as the nested `role_assignments` blocks in other variables. It uses `avm-res-authorization-roleassignment` (not the AVM interface block) and has a different field set: `scope` instead of parent-scoped, `managed_identity_key` for pattern cross-ref, and only 6 fields (no `skip_service_principal_aad_check`, `condition`, `condition_version`, `delegated_managed_identity_resource_id`). See contracts §3f for the correct template.
| 14 | `vhub_connectivity_definitions` | L851 | `map(object)` | vhub_vnet_connection submodule v0.13.5 | ~10 (routing, associated_route_table, propagated_route_tables) |
| 15 | `bastion_hosts` | L903 | `map(object)` | bastion_host v0.9.0 | ~20 (ip_configuration, diag, lock, role_assignments, sku) |
| 16 | `storage_accounts` | L1000 | `map(object)` | storage_account v0.6.7 | ~80+ (blob_properties, share_properties, queue_properties, network_rules, containers, managed_identities, PE, diag, lock, role_assignments) |
| 17 | `flowlog_configuration` | L1443 | `object` | network_watcher v0.3.2 | ~15 (flow_logs w/retention_policy, storage_account, traffic_analytics) |

**Total estimated leaf attributes**: ~350+

---

## Repeated Interface Blocks

These blocks appear in multiple variables and share canonical AVM text (see research.md §4).

| Block | Variables Containing It | Canonical Variant |
|-------|------------------------|-------------------|
| `lock` | resource_groups, log_analytics_workspace_configuration, network_security_groups, route_tables, virtual_networks, private_dns_zones, managed_identities, key_vaults, bastion_hosts, storage_accounts | Standard 2-field (kind, name) |
| `role_assignments` | resource_groups, log_analytics_workspace_configuration, network_security_groups, route_tables, virtual_networks, private_dns_zones, key_vaults, bastion_hosts, storage_accounts | Full 9-field (fix `<RESOURCE>`) |
| `role_assignments` (managed_identity variant) | managed_identities | Unique: uses `scope` instead of `principal_id` |
| `diagnostic_settings` | log_analytics_workspace_configuration, network_security_groups, virtual_networks, key_vaults, bastion_hosts, storage_accounts | Full 10-field (fix "Key Vault" bug) |
| `private_endpoints` | log_analytics_workspace_configuration, key_vaults, storage_accounts | Full with ip_configurations sub-block |
| `tags` (nested) | resource_groups, virtual_networks, bastion_hosts, storage_accounts, etc. | "(Optional) Tags to apply to this resource." |

---

## Cross-Reference Key Attributes

These pattern-specific keys reference other variable maps and need the `> **Pattern note:**` callout.

| Key Attribute | Found In Variables | References |
|---------------|-------------------|------------|
| `resource_group_key` | network_security_groups, route_tables, virtual_networks, private_dns_zones, managed_identities, key_vaults, bastion_hosts, storage_accounts | `resource_groups` variable |
| `vnet_key` | vhub_connectivity_definitions (virtual_network), flowlog_configuration (flow_logs) | `virtual_networks` variable |
| `virtual_network_key` | private_dns_zones (virtual_network_links), byo_private_dns_zone_links | `virtual_networks` variable |
| `subnet_key` | bastion_hosts (ip_configuration), key_vaults (private_endpoints), storage_accounts (private_endpoints) | `virtual_networks[].subnets` |
| `network_security_group_key` | virtual_networks (subnets) | `network_security_groups` variable |
| `route_table_key` | virtual_networks (subnets) | `route_tables` variable |
| `managed_identity_key` | key_vaults, role_assignments (standalone, L821) | `managed_identities` variable |

> **Removed (incorrect in prior version)**:
> - ~~`log_analytics_workspace_key`~~ — does not exist; flowlog `traffic_analytics` uses `workspace_id`/`workspace_resource_id` (resource IDs, not map keys)
> - ~~`storage_account_key`~~ — does not exist as an attribute; flowlog uses `storage_account.key` (nested field named `key` inside a `storage_account` object)
> - ~~`key_vault_key`~~ — does not exist; storage CMK uses `key_vault_resource_id` (resource ID, not key reference)
> - ~~`private_dns_zone_key`~~ — does not exist; the actual attribute is `virtual_network_key` (listed above)

---

## AVM Module Source Files for Description Extraction

| AVM Module | Primary Variable File(s) | Module Path Under `.terraform/modules/` |
|------------|------------------------|-----------------------------------------|
| resource_group v0.2.2 | `variables.tf` | `resource_group/` |
| log_analytics_workspace v0.5.1 | `variables.tf` | `log_analytics_workspace/` |
| NSG v0.5.1 | `variables.tf` | `network_security_group/` |
| route_table v0.5.0 | `variables.tf` | `route_table/` |
| virtual_network v0.17.1 | `variables.tf` | `virtual_network/` |
| private_dns_zone v0.5.0 | `variables.tf` | `private_dns_zone/` |
| private_dns_zone_link submodule v0.5.0 | `variables.tf` | `private_dns_zone_link/` or `private_dns_zone/modules/...` |
| managed_identity v0.4.0 | `variables.tf` | `managed_identity/` |
| key_vault v0.10.2 | `variables.tf` | `key_vault/` |
| storage_account v0.6.7 | `variables.tf`, `variables.storageaccount.tf`, `variables.diagnostics.tf`, `variables.container.tf`, `variables.queue.tf`, `variables.share.tf` | `storage_account/` |
| role_assignment v0.3.0 | `variables.tf` | `role_assignment/` |
| vhub_vnet_connection submodule v0.13.5 | `variables.tf` | `vhub_vnet_connection/` or `vhub_connectivity/modules/...` |
| bastion_host v0.9.0 | `variables.tf` | `bastion_host/` |
| network_watcher v0.3.2 | `variables.tf` | `network_watcher/` |

---

## Description Rewrite Priority Order

Recommended implementation order by complexity (simplest first):

| Priority | Variable | Complexity | Reason |
|----------|----------|-----------|--------|
| 1 | `location` | Trivial | Light polish only (FR-018) |
| 2 | `tags` | Trivial | Light polish only (FR-018) |
| 3 | `resource_groups` | Low | ~5 attrs, good template to establish pattern |
| 4 | `byo_log_analytics_workspace` | Low | ~2 attrs, simple object |
| 5 | `byo_private_dns_zone_links` | Low | ~5 attrs, cross-ref keys |
| 6 | `route_tables` | Low | ~12 attrs, standard interfaces |
| 7 | `role_assignments` | Low | ~6 attrs, standalone role assignment module |
| 8 | `network_security_groups` | Medium | ~18 attrs, security_rules nested object |
| 9 | `private_dns_zones` | Medium | ~15 attrs, virtual_network_links |
| 10 | `managed_identities` | Medium | ~12 attrs, unique role_assignments variant |
| 11 | `vhub_connectivity_definitions` | Medium | ~10 attrs, routing config |
| 12 | `bastion_hosts` | Medium | ~20 attrs, ip_configuration |
| 13 | `flowlog_configuration` | Medium | ~15 attrs, deeply nested flow_logs |
| 14 | `log_analytics_workspace_configuration` | High | ~45 attrs, many nested objects |
| 15 | `key_vaults` | High | ~50 attrs, keys/secrets/contacts with sub-objects |
| 16 | `virtual_networks` | Very High | ~55 attrs, subnets+peerings with 30+ fields each |
| 17 | `storage_accounts` | Very High | ~80+ attrs, largest variable, 6 AVM source files |
