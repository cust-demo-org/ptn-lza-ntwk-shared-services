# Research: AVM Variable Description Styles

**Feature**: 003-avm-variable-descriptions  
**Date**: 2026-03-17  
**Method**: Extracted verbatim variable descriptions from all 14 AVM modules under `examples/full/.terraform/modules/`

---

## 1. AVM Description Style — Canonical Patterns

### Decision: Use the "Full AVM interface" bullet-list style consistently

**Rationale**: The newest AVM modules (virtual_network v0.17.1, bastion_host v0.9.0, key_vault v0.10.2) all use this format. Older modules (resource_group v0.2.2) use a slightly different layout but the same structural elements.

**Canonical format**:
```
A map of <resource_type> to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `field_name` - (Required) Description of the field.
- `optional_field` - (Optional) Description. Defaults to `value`.
```

**Alternatives considered**:
- Dash-list without backticks (current pattern style) — rejected: doesn't match AVM
- Prose paragraphs — rejected: doesn't scale for 10+ field objects
- Cross-reference style ("See AVM module variable") — rejected per clarification Q2: must be self-contained

---

## 2. `(Required)` / `(Optional)` Marker Placement

### Decision: Use `- \`field\` - (Required/Optional) Description` format

**Rationale**: This is the dominant pattern across AVM modules. The `(Required)`/`(Optional)` marker appears after the backtick-dash separator, before the description text.

**Two styles found in AVM modules**:
1. **Standard** (most modules): `- \`field\` - (Optional) Description text.`
2. **Older** (resource_group): `- \`kind\` - (Required) The type of lock.` — same layout, slightly different wording

**Alternatives considered**:
- Markers at start of line: `Optional. A map of...` — found in resource_group top-level only, not for nested attributes
- No markers at all — found in key_vault `keys`/`secrets` attributes; rejected for consistency

**Decision**: Always include `(Required)` or `(Optional)` on every leaf attribute bullet. Normalize older modules' descriptions to include markers even where the AVM source omits them.

---

## 3. Deliberately Arbitrary Map Keys Statement

### Decision: Use the exact AVM wording for every `map(object({...}))` variable

**Rationale**: The phrase is identical across all AVM modules.

**Exact wording**: "The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time."

**Note**: The AVM text uses "maybe" (one word) rather than "may be" (two words). We preserve the exact AVM wording per FR-003.

**Applicable variables** (all `map(object({...}))` types):
- `resource_groups`, `virtual_networks`, `network_security_groups`, `route_tables`
- `private_dns_zones`, `managed_identities`, `key_vaults`, `storage_accounts`
- `bastion_hosts`, `flowlog_configuration` (inner `flow_logs` map)
- Nested maps within variables: `role_assignments`, `diagnostic_settings`, `private_endpoints`, `containers`, `security_rules`, `subnets`, `peerings`, `tables`, `data_exports`, etc.

---

## 4. Repeated Interface Blocks — Canonical Text

### 4a. `lock` Block

**Decision**: Use the standard AVM lock description (2 fields: `kind`, `name`)

**Canonical text**:
```
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
```

**Three variants found in AVM**:
1. **Standard** (most common — resource_group, virtual_network, bastion_host, NSG, route_table, LAW, managed_identity, network_watcher, private_dns_zone): Full two-field description above
2. **Short form** (key_vault, storage_account): `The lock level to apply. Default is \`None\`. Possible values are \`None\`, \`CanNotDelete\`, and \`ReadOnly\`.`
3. **resource_group variant**: Same as #1 but with 2-space leading indent

**Decision**: Use the standard variant (#1) for all variables in the pattern module. The short form is used by older AVM modules and doesn't document the `name` field.

### 4b. `role_assignments` Block

**Decision**: Use the "Full 9-field" variant (newest) and fix the `<RESOURCE>` placeholder

**Canonical text** (template — replace `{resource}` with actual resource name):
```
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
```

**Three variants found in AVM**:
1. **Full 9-field** (virtual_network, bastion_host, network_watcher, private_dns_zone, LAW): All 8 attribute fields + Note callout. Has `<RESOURCE>` placeholder bug.
2. **Simple 7-field** (resource_group, key_vault, NSG, route_table, storage_account): Omits `delegated_managed_identity_resource_id` and/or `principal_type`. Inconsistent `(Optional)` markers.
3. **managed_identity variant**: Uses `scope` instead of `principal_id`, has `any_principals` and federated fields. Completely different structure.

**Decision**: Use Full 9-field variant as baseline. Replace `<RESOURCE>` with the actual resource being described. For managed_identity, use its unique structure (has `scope`).

### 4c. `diagnostic_settings` Block

**Decision**: Use the full AVM diagnostic_settings description and fix the "Key Vault" copy-paste bug

**Canonical text** (template):
```
A map of diagnostic settings to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
```

**Copy-paste bug found**: Several modules (virtual_network, bastion_host, NSG, LAW) have "Key Vault" text in their diagnostic_settings description. The pattern module must use the resource-neutral version above.

### 4d. `private_endpoints` Block

**Decision**: Use the full AVM private_endpoints description with all sub-attributes

**Key fields**: `name`, `role_assignments`, `lock`, `tags`, `subnet_resource_id`, `private_dns_zone_resource_ids`, `application_security_group_associations`, `application_security_group_resource_ids`, `private_service_connection_name`, `network_interface_name`, `location`, `resource_group_resource_id`, `ip_configurations` (nested with `name`, `private_ip_address`, `member_name`, `subresource_name`)

**Note**: Only key_vault, storage_account, and LAW have private_endpoints in the pattern module.

---

## 5. Pattern-Specific Notes

### Decision: Append pattern notes after AVM text using `> **Pattern note:**` callout

**Rationale**: Per FR-009 and clarification Q1, pattern-specific notes must be clearly distinguished. A blockquote callout provides visual separation in both source and rendered Markdown.

**Pattern-specific behaviors to document**:
| Variable | Pattern Note |
|----------|-------------|
| All variables with `resource_group_key` | "Must match a key in the `resource_groups` variable." |
| All variables with `location` override | "Defaults to `var.location` if not specified." |
| All variables with `tags` override | "Merged with `var.tags`." |
| `diagnostic_settings` with `use_default_log_analytics` | "When `true`, automatically sets `workspace_resource_id` to the Log Analytics workspace created by this pattern." |
| Cross-reference keys (`vnet_key`, `subnet_key`, etc.) | "Must match a key in the `virtual_networks` variable." / appropriate target |
| `flowlog_configuration.network_watcher` | "Created by this pattern if `flowlog_configuration` is provided." |

---

## 6. Copy-Paste Bugs to Fix

### Decision: Fix all known AVM copy-paste artifacts when reusing text

| Bug | Found In | Fix |
|-----|----------|-----|
| `<RESOURCE>` placeholder not replaced | virtual_network, bastion_host, network_watcher, private_dns_zone, LAW role_assignments | Replace with actual resource name (e.g., "the virtual network") |
| "Key Vault" in diagnostic_settings | virtual_network, bastion_host, NSG, LAW | Replace with resource-neutral wording or actual resource name |
| "container app environment" in managed_identity role_assignments | managed_identity | Replace with "the managed identity" |
| "A map of role flow logs" typo | network_watcher flow_logs | Fix to "A map of flow logs" |

---

## 7. Storage Account Description Sources

### Decision: Merge descriptions from all 6 AVM variable files

**Rationale**: The AVM `storage_account` module splits variables across 6 files:
- `variables.tf` — core: `lock`, `managed_identities`, `private_endpoints`, `role_assignments`, `network_rules`, `diagnostic_settings`
- `variables.storageaccount.tf` — `shared_access_key_enabled`, `infrastructure_encryption_enabled`, etc.
- `variables.diagnostics.tf` — `diagnostic_settings_blob`, `diagnostic_settings_file`, `diagnostic_settings_queue`, `diagnostic_settings_table`
- `variables.container.tf` — `containers` map
- `variables.queue.tf` — `queue_properties` (including `cors_rule`, `hour_metrics`, `logging`, `minute_metrics`)
- `variables.share.tf` — `share_properties` (including `cors_rule`, `retention_policy`, `smb`)

The pattern module's `storage_accounts` variable inlines all of these as nested objects. Each sub-object description must be sourced from the correct AVM file.

---

## 8. Managed Identity `role_assignments` Difference

### Decision: Document managed_identity role_assignments with its unique `scope` field

**Rationale**: The AVM managed_identity module has a structurally different `role_assignments` variable that uses `scope` (Azure resource ID) instead of `principal_id` (the identity is implicit since it IS the managed identity).

**Key difference**: Standard role_assignments assigns a role TO a principal ON a resource. Managed identity role_assignments assigns a role FOR the identity ON an external scope.

**Unique fields**:
- `scope` - The resource ID to assign the role on
- `role_definition_id_or_name` - Same as standard
- `description`, `skip_service_principal_aad_check`, `condition`, `condition_version` - Same as standard
- No `principal_id` or `principal_type` (the managed identity IS the principal)

---

## 9. Variables Requiring Special Treatment

### `location` and `tags` (FR-018)

**Decision**: Light polish only — paragraph style, backtick formatting consistency

**Rationale**: Per clarification Q5, these are simple scalars with no nested attributes. Full AVM bullet-list rewrite would be over-engineering.

### `flowlog_configuration`

**Decision**: Document as a single-key object (only `flow_logs` inner map)

**Rationale**: This variable wraps the AVM network_watcher module's `flow_logs` variable. The pattern creates the network_watcher resource automatically; the user configures only the flow logs themselves.

### `virtual_networks` subnets and peerings

**Decision**: Document all ~30 peering attributes and ~15 subnet attributes individually (per clarification Q3)

**Rationale**: Every leaf gets its own bullet — no exceptions. This is the largest variable description and will be the most work.

---

## Summary of Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Use full AVM bullet-list style | Matches newest AVM modules, most complete format |
| 2 | Always include `(Required)`/`(Optional)` markers | Normalize across modules for consistency |
| 3 | Preserve exact "deliberately arbitrary" wording | FR-003: reuse AVM text verbatim |
| 4a | Use standard 2-field lock description | Most complete; documents both `kind` and `name` |
| 4b | Use full 9-field role_assignments | Newest variant; fix `<RESOURCE>` placeholder |
| 4c | Use resource-neutral diagnostic_settings | Fix "Key Vault" copy-paste bug |
| 4d | Use full private_endpoints with sub-attributes | Complete nested documentation |
| 5 | Pattern notes in `> **Pattern note:**` callout | Visual separation from AVM text |
| 6 | Fix all copy-paste bugs | Don't propagate AVM module errors |
| 7 | Merge storage_account from 6 AVM files | Complete source coverage |
| 8 | managed_identity role_assignments uses `scope` | Structurally different from standard |
| 9 | Light polish for location/tags | Per clarification Q5 |
