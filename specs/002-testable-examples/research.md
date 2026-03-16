# Research: Testable Examples

**Feature**: 002-testable-examples | **Date**: 2026-03-10

## R1: AVM Example Pattern (variables.tf + terraform.tfvars)

**Decision**: Each example exposes all pattern module variables via `variables.tf` with defaults; `terraform.tfvars` provides scenario-specific overrides. Dependent resources (RG, hub VNet, vWAN, etc.) are hardcoded in `main.tf`.

**Rationale**: The AVM convention (reference: [terraform-azurerm-avm-res-network-firewallpolicy](https://github.com/Azure/terraform-azurerm-avm-res-network-firewallpolicy)) uses this pattern: examples declare variables with defaults so `terraform plan` works with no inputs, while `.tfvars` provides real deployment values. This enables both zero-input CI testing and realistic deployments with custom values.

**Alternatives considered**:
- Hardcode all values in `main.tf` (original spec approach) — Rejected: doesn't test the variable interface; consumers can't see how to override values.
- Only use `.tfvars` with no `variables.tf` — Rejected: `terraform plan` would require `-var-file` flag, violating the "no required inputs" convention.

## R2: Provider Version Pinning Strategy

**Decision**: Examples pin providers to exact versions: `azurerm = "4.63.0"`, `azapi = "2.8.0"`, `random = "3.8.1"`. The root module retains range constraints (`~> 4.0`, `~> 2.0`, `~> 3.0`).

**Rationale**: Exact pins in examples ensure reproducible `terraform plan` output. The root module keeps range constraints for consumer flexibility. This mirrors AVM practices where examples pin versions for CI stability.

**Alternatives considered**:
- Range constraints in examples (mirrors root) — Rejected: plan output varies as providers release new versions; CI tests become flaky.
- Pin root module to exact versions — Rejected: overly restrictive for consumers who may need different minor versions.

## R3: Example Directory Taxonomy (4 Examples)

**Decision**: Four examples covering progressive feature complexity:

| Example | Purpose | Inline Dependencies | Pattern Features Tested |
|---------|---------|----------------------|------------------------|
| `minimal/` | Simplest viable deployment | RG, naming | resource_groups, log_analytics, NSGs, route_tables, VNets (no peering) |
| `vnet_hub/` | VNet-to-VNet hub peering | RG, naming, hub VNet | All minimal features + VNet peering to hub |
| `vwan_hub/` | vWAN hub connectivity | RG, naming, vWAN, vHub | All minimal features + vhub_connectivity_definitions |
| `full/` | Every optional feature | RG, naming, hub VNet, DNS zone, Network Watcher, public IP, storage account | ALL pattern features: Bastion, Key Vault, managed identities, role assignments, flow logs, DNS links, peering |

**Rationale**: The original spec had 3 examples. Adding `vnet_hub/` separates the common VNet peering scenario from the minimal case (which now omits peering entirely). Renaming `vwan/` to `vwan_hub/` clarifies it connects to a vWAN hub, not just configures a vWAN.

**Alternatives considered**:
- 3 examples (minimal with peering, full, vwan) — Rejected: minimal should be truly minimal (no peering); VNet hub peering deserves its own dedicated example.
- 5+ examples (one per feature) — Rejected: too many examples to maintain; progressive complexity with 4 is enough coverage.

## R4: AVM Variable Pass-Through Audit

**Decision**: Based on audit of all 13 AVM module calls, the following fields should be added to root module variable types (FR-021):

### High Priority (common operational patterns)

| Variable | Missing Field | AVM Module | Justification |
|----------|--------------|------------|---------------|
| `resource_groups` | `role_assignments` | resource_group v0.2.2 | Per-RG RBAC is common (e.g., Reader for monitoring, Contributor for app teams) |
| `resource_groups` | `lock` | resource_group v0.2.2 | Per-RG lock overrides allow different lock policies per RG |
| `log_analytics_workspace_configuration` | `role_assignments` | log_analytics v0.5.1 | LAW RBAC for data access control |
| `network_security_groups` | `role_assignments` | nsg v0.5.1 | Per-NSG RBAC for network team delegation |
| `managed_identities` | `role_assignments` | managed_identity v0.4.0 | Bootstrap permissions at identity creation time |

### Medium Priority (nice-to-have for completeness)

| Variable | Missing Field | AVM Module | Justification |
|----------|--------------|------------|---------------|
| `log_analytics_workspace_configuration` | `private_endpoints` (key-based) | log_analytics v0.5.1 | Private Link access for LAW. Uses key-based reference pattern (see R8). |
| `bastion_hosts` | `role_assignments` | bastion v0.9.0 | Per-Bastion RBAC |
| `virtual_networks` | `role_assignments` (VNet-level) | vnet v0.17.1 | Subnet-level already exposed; VNet-level is supplementary |

### Intentionally Excluded

| Variable | Field | Reason |
|----------|-------|--------|
| `byo_private_dns_zone_links` | `lock` | Submodule doesn't support lock interface |
| `vhub_connectivity_definitions` | `tags` | Azure vHub connections don't support tagging |
| All modules | `customer_managed_key` | Scope creep — CMK is a separate feature concern |
| Route tables | `diagnostic_settings` | Auto-default diagnostic settings already applied |

**Rationale**: Focus on `role_assignments` pass-through as the most commonly needed field across modules. `lock` on resource_groups enables per-RG lock policies. Keeping diagnostic_settings as auto-configured (to LAW) is the right pattern — consumers shouldn't need to configure individual diagnostic targets.

**Alternatives considered**:
- Pass through EVERY AVM variable — Rejected: many fields (customer_managed_key, managed_identities on KV, etc.) are not applicable or would cause scope creep.
- Only add `role_assignments` to resource_groups — Rejected: user explicitly flagged this as an audit across all modules; the high-priority set covers the most useful additions.

## R8: Private Endpoint Key-Based Reference Pattern

**Decision**: Private endpoints on `log_analytics_workspace_configuration` and `key_vaults[]` use a key-based reference pattern with `network_configuration` and `private_dns_zone` sub-objects, instead of flat `subnet_resource_id` / `private_dns_zone_resource_ids` fields.

**New PE shape**:
```hcl
private_endpoints = optional(map(object({
  name = optional(string, null)
  network_configuration = object({
    subnet_resource_id = optional(string)
    vnet_key           = optional(string)
    subnet_key         = optional(string)
  })
  private_dns_zone = optional(object({
    resource_ids = optional(set(string))
    keys         = optional(set(string))
  }))
  tags = optional(map(string), null)
})), {})
```

**Resolution logic in root main.tf** (via locals — see R11):
- Subnet: `coalesce(pe.network_configuration.subnet_resource_id, local.subnet_resource_ids[pe.network_configuration.vnet_key][pe.network_configuration.subnet_key])`
- DNS zones: `setunion(pe.private_dns_zone.resource_ids, [for k in pe.private_dns_zone.keys : var.byo_private_dns_zone_links[k].private_dns_zone_id])`

**Rationale**: The key-based pattern eliminates the need for callers to look up computed subnet IDs and DNS zone IDs themselves. Consumers reference resources by their map keys (from `virtual_networks` and `byo_private_dns_zone_links`). The pattern module performs the ID resolution internally. This removes the `key_vaults` local block previously needed in `full/main.tf` to merge computed IDs.

**Impact on examples**: The `full/` example's `terraform.tfvars` now declares PE configs using `vnet_key`/`subnet_key` and `private_dns_zone.keys` instead of hardcoded resource IDs or computed locals. No `key_vaults` local is needed in `main.tf`.

**Alternatives considered**:
- Keep flat `subnet_resource_id` / `private_dns_zone_resource_ids` — Rejected: forces callers to resolve IDs themselves; examples needed fragile locals to merge computed values.
- Only support keys, no direct IDs — Rejected: direct `subnet_resource_id` and `resource_ids` remain for advanced scenarios (e.g., cross-module references to resources not managed by this pattern).

## R9: vHub / DDoS Field Renames

**Decision**: `vhub_connectivity_definitions.virtual_network.id` renamed to `.resource_id`. `ddos_protection_plan.id` renamed to `.resource_id`.

**Rationale**: Consistent naming with AVM conventions where resource identifiers use `resource_id` suffix. The `.id` suffix is ambiguous (could be a short name or ARM resource ID). Matching fixes applied in `locals.tf` and validation blocks.

## R10: Bastion Key-Based Reference Pattern

**Decision**: `bastion_hosts` uses the same key-based reference pattern as private endpoints, applied to two fields:
1. `ip_configuration.network_configuration` — same structure as PE `network_configuration` (`subnet_resource_id` or `vnet_key`/`subnet_key`)
2. `virtual_network` — an object with `resource_id` (direct) or `key` (resolved from `virtual_networks` map), matching the `vhub_connectivity_definitions.virtual_network` pattern

**Bastion variable shape**:
```hcl
bastion_hosts = map(object({
  # ... other fields ...
  ip_configuration = optional(object({
    name = optional(string)
    network_configuration = object({
      subnet_resource_id = optional(string)  # Direct ID — OR use key-based:
      vnet_key           = optional(string)  # Key in virtual_networks map
      subnet_key         = optional(string)  # Key in the VNet's subnets map
    })
    create_public_ip     = optional(bool, true)
    public_ip_address_id = optional(string, null)
    # ... other ip_configuration fields ...
  }))
  virtual_network = optional(object({
    resource_id = optional(string)  # Direct ARM resource ID
    key         = optional(string)  # Key in virtual_networks map
  }))
}))
```

**Resolution logic in root main.tf** (via locals — see R11):
- `ip_configuration.subnet_id`: `coalesce(network_configuration.subnet_resource_id, local.subnet_resource_ids[vnet_key][subnet_key])`
- `virtual_network_id`: `coalesce(virtual_network.resource_id, local.vnet_resource_ids[virtual_network.key])`

**Rationale**: Consistency — the same `network_configuration` pattern used for PEs is now used for bastion subnet resolution. The `virtual_network` object mirrors `vhub_connectivity_definitions.virtual_network`. Callers use map keys instead of computing resource IDs.

**Impact on examples**: The `full/` example's `terraform.tfvars` sets bastion subnet via keys (`vnet_key = "vnet_spoke"`, `subnet_key = "AzureBastionSubnet"`). The `main.tf` only needs to merge `public_ip_address_id` in the bastion locals — subnet resolution is handled by the pattern module.

## R11: Locals Refactoring — VNet and Subnet Resource ID Lookups

**Decision**: Two new lookup maps added to `locals.tf` for cleaner referencing:
```hcl
vnet_resource_ids   = { for key, mod in module.virtual_network : key => mod.resource_id }
subnet_resource_ids = { for key, mod in module.virtual_network : key => { for sk, sv in mod.subnets : sk => sv.resource_id } }
```

**Rationale**: Before this refactoring, every reference to a VNet or subnet ID required the verbose `module.virtual_network[key].resource_id` or `module.virtual_network[key].subnets[sk].resource_id`. With 6+ references across `main.tf` and `locals.tf` (PE resolution, DNS zone links, bastion, vHub), this was repetitive. The new locals follow the same pattern as existing `nsg_resource_ids`, `rt_resource_ids`, and `managed_identity_principal_ids`.

**References updated** (all `module.virtual_network[...]` replaced with `local.*`):
| Location | Old Reference | New Reference |
|----------|--------------|---------------|
| LAW PE subnet | `module.virtual_network[vnet_key].subnets[subnet_key].resource_id` | `local.subnet_resource_ids[vnet_key][subnet_key]` |
| Key Vault PE subnet | same | `local.subnet_resource_ids[vnet_key][subnet_key]` |
| DNS zone link | `module.virtual_network[key].resource_id` | `local.vnet_resource_ids[key]` |
| Bastion subnet | same as PE | `local.subnet_resource_ids[vnet_key][subnet_key]` |
| Bastion VNet | `module.virtual_network[key].resource_id` | `local.vnet_resource_ids[key]` |
| vHub VNet (in locals) | `module.virtual_network[key].resource_id` | `local.vnet_resource_ids[key]` |

## R5: Variable Description Improvement Pattern (FR-020)

**Decision**: Root module variable descriptions will use multi-line heredoc format (`<<-EOT ... EOT`) referencing the specific AVM module and variable they map to.

**Example pattern**:
```hcl
variable "resource_groups" {
  type = map(object({
    name               = string
    location           = optional(string)
    tags               = optional(map(string), {})
    lock               = optional(object({ ... }))
    role_assignments   = optional(map(object({ ... })), {})
  }))
  description = <<-EOT
    Map of resource groups to create. The map key is used as a reference key for other resources.

    Uses: Azure/avm-res-resources-resourcegroup/azurerm v0.2.2
    See: https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm

    - name:             Resource group name.
    - location:         Azure region. Defaults to var.location if not specified.
    - tags:             Per-resource-group tags, merged with var.tags.
    - lock:             Per-resource-group lock override. Defaults to var.lock.
                        See AVM module variable: lock.
    - role_assignments: Per-resource-group RBAC assignments.
                        See AVM module variable: role_assignments.
  EOT
}
```

**Rationale**: Heredoc descriptions allow structured multi-line content visible in terraform-docs output. Referencing AVM module + variable name lets consumers trace each field back to the upstream documentation.

**Alternatives considered**:
- Single-line descriptions (current) — Rejected: insufficient for complex object types; consumers can't trace fields to AVM docs.
- External documentation only — Rejected: violates Constitution Principle VI (descriptions must be on the variable itself).

## R6: terraform-docs Configuration per Example

**Decision**: Each example gets a `_header.md` + terraform-docs generated `README.md`. No footer needed. The `_header.md` describes what the example demonstrates, following the AVM convention. terraform-docs markers (`<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->`) are used.

**Rationale**: Constitution Principle VI mandates terraform-docs for all module directories. Examples are root modules and need documented inputs/outputs for consumers.

**Alternatives considered**:
- No README in examples — Rejected: violates Constitution Principle VI.
- Manual README without terraform-docs — Rejected: documentation drifts.

## R7: Inline Dependency Strategy per Example

**Decision**: Each example deploys dependencies using `azurerm_*` resource blocks (not AVM modules) for dependent resources that exist solely to satisfy pattern module prerequisites.

| Example | Inline Resource | Purpose |
|---------|----------------|---------|
| All | `azurerm_resource_group` (or AVM naming + pattern call) | Base requirement |
| `vnet_hub/` | `azurerm_virtual_network` (hub) | Peering target for spoke VNet |
| `vwan_hub/` | `azurerm_virtual_wan`, `azurerm_virtual_hub` | vHub connectivity target |
| `full/` | `azurerm_virtual_network` (hub), `azurerm_private_dns_zone`, `azurerm_network_watcher` (if not auto-created), `azurerm_public_ip`, `azurerm_storage_account` | All feature dependencies |

**`depends_on` requirement**: When inline `azurerm_*` resources are referenced by the pattern module (via computed IDs passed through locals), the `module "pattern"` block **must** include an explicit `depends_on` listing all inline resources it depends on. This ensures Terraform creates the inline resources before the pattern module attempts to use their IDs. Examples: `depends_on = [ azurerm_virtual_network.hub ]` (vnet_hub), `depends_on = [ azurerm_virtual_hub.main ]` (vwan_hub), and the full list for `full/`. The `minimal/` example has no inline dependencies and does not need `depends_on`.

**Note**: Using `azurerm_*` for inline deps (not AVM) is acceptable per Constitution Principle II exemption: "Custom resource blocks are permitted ONLY when no AVM module exists for the resource type AND the omission is documented." In the examples context, these are ephemeral test dependencies, not pattern infrastructure. However, `azurerm_resource_group` could be replaced by an AVM naming call + the pattern module creating the RG. The decision here is that **the RG is created by the pattern module itself** (via the `resource_groups` variable), so examples only deploy resources the pattern does NOT create.

**Rationale**: Inline `azurerm_*` resources are simpler, faster, and avoid AVM module version management for ephemeral test infrastructure.

## R12: Storage Account Module & Flow Log Key-Based Reference

**Decision**: Add `var.storage_accounts` (map of objects) backed by AVM storage module v0.6.7 (`Azure/avm-res-storage-storageaccount/azurerm`). Flow log `storage_account_id` is replaced with a nested `storage_account` object supporting both `resource_id` (direct) and `key` (reference to `storage_accounts` map).

**Pattern**: Same `coalesce(direct_resource_id, local.lookup[key])` used for PE subnets, bastion, and vHub VNet references. The nested object pattern (`storage_account = { resource_id, key }`) mirrors `virtual_network = { resource_id, key }` used by bastion and vHub.

**Storage account variable** exposes key AVM pass-through fields with secure defaults:
- `shared_access_key_enabled = false` (Entra-only auth)
- `public_network_access_enabled = false` (secure-by-default)
- `network_rules.default_action = "Deny"` (deny by default)
- `min_tls_version = "TLS1_2"`
- Private endpoints with the same `network_configuration = { subnet_resource_id | vnet_key + subnet_key }` pattern

**Locals addition**: `storage_account_resource_ids = { for key, mod in module.storage_account : key => mod.resource_id }`

**Diagnostic settings**: AVM storage module uses `diagnostic_settings_storage_account` (not `diagnostic_settings`). Separate settings exist for blob, file, queue, table sub-resources.

**Validation preconditions** added:
1. Each flow log must set exactly one of `storage_account.resource_id` or `storage_account.key`
2. `storage_account.key` must reference a valid key in `var.storage_accounts`

**Output**: `storage_accounts` output added to expose `resource_id` and `name` per key.

**Alternatives considered**:
- Flat fields `storage_account_id` + `storage_account_key` — Rejected: nested object is more consistent with existing patterns (bastion `virtual_network`, vHub `virtual_network`).
- Pass entire flow_logs map through without transformation — Rejected: prevents key-based resolution; requires consumers to pre-resolve IDs externally.
- Inline `azurerm_storage_account` in `full/` example — Rejected: the `full/` example should exercise the pattern module's `storage_accounts` feature end-to-end via key-based reference (`storage_account = { key = "sa_flowlog" }`).

## R13: Flow Log VNet Key-Based Target Reference

**Decision**: Replace `flow_logs.target_resource_id` (open string) with `flow_logs.vnet_key` (key in `virtual_networks` map). Flow logs in this pattern module always target VNets created by the module, so there is no need to accept an arbitrary resource ID.

**Resolution**: `target_resource_id = local.vnet_resource_ids[fl.vnet_key]` — same lookup map used by DNS zone links, bastion VNet, and vHub VNet.

**Validation precondition** added: `vnet_key` must exist in `var.virtual_networks`.

**Impact on `full/` example**: Removed `target_resource_id = local.spoke_vnet_id` override from `main.tf` locals — the pattern module resolves `vnet_key` internally. Also cleaned up dead locals (`spoke_vnet_name`, `spoke_vnet_id`, `spoke_bastion_subnet_id`) that were only used for the old `target_resource_id` merge.

**Alternatives considered**:
- Keep `target_resource_id` alongside `vnet_key` (dual-mode like storage_account) — Rejected: unlike storage accounts that may exist outside the module, flow log targets are always module-managed VNets.
- Keep `target_resource_id` only — Rejected: requires callers to pre-resolve VNet IDs externally, inconsistent with the key-based philosophy.

## R14: Optional Network Watcher Fields with Azure Standard Defaults

**Decision**: Make `flowlog_configuration.network_watcher_id`, `network_watcher_name`, and `resource_group_name` optional (defaulting to `null`). The pattern module computes Azure standard defaults using `coalesce`:

- `resource_group_name` → `"NetworkWatcherRG"`
- `network_watcher_name` → `"NetworkWatcher_<location>"` (uses `flowlog_configuration.location` or `var.location`)
- `network_watcher_id` → constructed from subscription ID + the above defaults

**Resolution**: Azure auto-creates `NetworkWatcherRG` and `NetworkWatcher_<region>` when the first VNet is deployed in a subscription. Since the vast majority of deployments use these standard resources, callers should not be required to supply these values. The `coalesce` pattern allows callers to override if they have a custom Network Watcher.

**Impact on `full/` example**: Removed `nw_rg_name`, `nw_name`, `nw_id` locals and their merge overrides from `main.tf` — the pattern module now computes these internally. The `terraform.tfvars` commented block no longer shows the 3 NW fields.

**Alternatives considered**:
- Keep all 3 fields required — Rejected: forces callers to manually construct the NW resource ID, which is boilerplate for the standard case.
- Use a `data` source to look up the Network Watcher — Rejected: data source fails during `terraform plan` if the NW doesn't yet exist (common in fresh subscriptions where VNets haven't been deployed).

## R15: BYO Log Analytics Workspace & Auto-Resolved Traffic Analytics

**Decision**: Replace `var.log_analytics_workspace_id` (flat string) with `var.byo_log_analytics_workspace` (object with `resource_id` and `location`). Make `traffic_analytics.workspace_id`, `workspace_region`, and `workspace_resource_id` optional — the pattern module auto-resolves them from the Log Analytics workspace (internal or BYO).

**Resolution**:
- `byo_log_analytics_workspace` provides both `resource_id` and `location` when an external workspace is used. A `data "azurerm_log_analytics_workspace" "external"` data source (count-gated) retrieves the workspace GUID for the external case.
- Three new locals in `locals.tf`:
  - `log_analytics_workspace_resource_id` — coalesce of BYO resource_id and internal module resource_id (renamed from `log_analytics_workspace_id` for clarity)
  - `law_workspace_id` — GUID from data source (BYO) or `module.log_analytics_workspace[0].resource.workspace_id` (internal)
  - `law_workspace_region` — from `byo_log_analytics_workspace.location` (BYO) or `coalesce(config.location, var.location)` (internal)
- `traffic_analytics` fields in the network_watcher module call use `coalesce(fl.traffic_analytics.<field>, local.<resolved>)` so callers can optionally override.

**Impact on `full/` example**: Removed `law_rg_name`, `law_name`, `law_resource_id` locals and the `workspace_resource_id` merge override from `main.tf` — the pattern module resolves all traffic analytics workspace fields internally. The `terraform.tfvars` traffic_analytics block no longer needs `workspace_id`, `workspace_region`, or `workspace_resource_id`.

**Alternatives considered**:
- Keep `log_analytics_workspace_id` as a flat string — Rejected: doesn't provide `location` needed for `workspace_region`; callers must manually construct 3 traffic analytics fields.
- Always use a data source for the internal LAW — Rejected: the internal module already exposes `.resource.workspace_id` directly, no need for a redundant data source lookup.
