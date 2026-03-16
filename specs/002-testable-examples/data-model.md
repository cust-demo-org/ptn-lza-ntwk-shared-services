# Data Model: Testable Examples

**Feature**: 002-testable-examples | **Date**: 2026-03-10

## Entity: Example Directory

Each example directory is a self-contained Terraform root module.

### File Composition

| File | Required | Purpose |
|------|----------|---------|
| `terraform.tf` | YES | Provider pins (exact versions) + required_version |
| `main.tf` | YES | Inline dependencies + `module "pattern" { source = "../.." }` call |
| `variables.tf` | YES | All pattern module variables with scenario defaults |
| `terraform.tfvars` | YES | Scenario-specific value overrides |
| `_header.md` | YES | terraform-docs header describing the example |
| `README.md` | YES | terraform-docs generated (auto from _header.md + docs) |

### State Transitions

```
.tfvars-only → scaffold (terraform.tf + main.tf + variables.tf) → terraform.tfvars populated → _header.md + README.md → validation (plan/fmt/validate)
```

## Entity: Example Variables Mapping

Each example's `variables.tf` mirrors the root module's 17+ variables. All have defaults.

### Variable-to-Example Feature Matrix

| Variable | minimal | vnet_hub | vwan_hub | full | Default (when unused) |
|----------|---------|----------|----------|------|----------------------|
| `location` | ✅ | ✅ | ✅ | ✅ | `"australiaeast"` |
| `tags` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `lock` | ❌ | ❌ | ❌ | ❌ | `null` |
| `resource_groups` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `byo_log_analytics_workspace` | ❌ | ❌ | ❌ | ❌ | `null` |
| `log_analytics_workspace_configuration` | ✅ | ✅ | ✅ | ✅ | `null` |
| `network_security_groups` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `route_tables` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `virtual_networks` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `private_dns_zones` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `byo_private_dns_zone_links` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `managed_identities` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `key_vaults` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `role_assignments` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `vhub_connectivity_definitions` | ❌ | ❌ | ✅ | ❌ | `{}` |
| `bastion_hosts` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `flowlog_configuration` | ❌ | ❌ | ❌ | ✅ | `null` |

Legend: ✅ = overridden in terraform.tfvars, ❌ = uses default (feature not exercised in this example)

## Entity: Inline Dependency Model

Resources deployed directly in `main.tf` per example (NOT through the pattern module).

### minimal/
```
azurerm_resource_group — NO (created by pattern module via resource_groups var)

module "pattern" (source = "../..") — the module under test
```

### vnet_hub/
```
azurerm_resource_group — hub RG (separate from spoke)
azurerm_virtual_network — hub VNet (peering target)
module "pattern" — depends_on = [ azurerm_virtual_network.hub ]
```

### vwan_hub/
```
azurerm_resource_group — connectivity RG
azurerm_virtual_wan
azurerm_virtual_hub
module "pattern" — depends_on = [ azurerm_virtual_hub.main ]
```

### full/
```
azurerm_resource_group — hub/connectivity RG
azurerm_virtual_network — hub VNet (peering target)
azurerm_private_dns_zone — for byo_private_dns_zone_links
azurerm_public_ip — for Bastion
module "pattern" — depends_on = [ azurerm_virtual_network.hub, azurerm_private_dns_zone.blob, azurerm_private_dns_zone.kv ]
```

**Note**: The hub resource group is created inline only for examples that need external dependencies (hub VNet, vWAN, etc.). The spoke's resource groups are created by the pattern module itself. The flow-log storage account is created by the pattern module via `storage_accounts` variable (key-based reference `sa_flowlog`).

## Entity: Root Module Variable Extensions (FR-021)

New fields to add to existing root module variable types.

### resource_groups
```hcl
# ADD:
lock             = optional(object({ kind = string, name = optional(string, null) }))
role_assignments = optional(map(object({
  role_definition_id_or_name             = string
  principal_id                           = string
  description                            = optional(string, null)
  skip_service_principal_aad_check       = optional(bool, false)
  condition                              = optional(string, null)
  condition_version                      = optional(string, null)
  delegated_managed_identity_resource_id = optional(string, null)
  principal_type                         = optional(string, null)
})), {})
```

### log_analytics_workspace_configuration
```hcl
# ADD:
role_assignments = optional(map(object({ ... })), {})  # Same shape as above
```

### network_security_groups
```hcl
# ADD:
role_assignments = optional(map(object({ ... })), {})
```

### managed_identities
```hcl
# ADD:
role_assignments = optional(map(object({ ... })), {})
```

### bastion_hosts
```hcl
# ADD:
role_assignments = optional(map(object({ ... })), {})
```

### virtual_networks (VNet-level)
```hcl
# ADD:
role_assignments = optional(map(object({ ... })), {})  # At VNet level, not just subnet level
```

## Entity: Private Endpoint Key-Based Reference Pattern

Private endpoints on `log_analytics_workspace_configuration` and `key_vaults[]` now use a
key-based reference pattern instead of flat resource IDs. The pattern module resolves keys
internally — callers no longer need to merge computed IDs in locals.

### PE Variable Shape (replaces old flat format)
```hcl
private_endpoints = optional(map(object({
  name = optional(string, null)
  network_configuration = object({
    subnet_resource_id = optional(string)   # Direct ID — OR use key-based:
    vnet_key           = optional(string)   # Key in virtual_networks map
    subnet_key         = optional(string)   # Key in the VNet's subnets map
  })
  private_dns_zone = optional(object({
    resource_ids = optional(set(string))     # Direct IDs — OR use key-based:
    keys         = optional(set(string))     # Keys in byo_private_dns_zone_links map
  }))
  tags = optional(map(string), null)
})), {})
```

### Resolution Logic (root main.tf, via locals)

- **Subnet**: `coalesce(pe.network_configuration.subnet_resource_id, local.subnet_resource_ids[pe.network_configuration.vnet_key][pe.network_configuration.subnet_key])`
- **DNS zones**: `setunion(pe.private_dns_zone.resource_ids, [for k in pe.private_dns_zone.keys : var.byo_private_dns_zone_links[k].private_dns_zone_id])`

### Affected Variables

| Variable | PE Field Path |
|----------|---------------|
| `log_analytics_workspace_configuration` | `.private_endpoints` |
| `key_vaults[]` | `.private_endpoints` |

### Impact on Examples

The `full/` example's `terraform.tfvars` sets PE config using keys:
```hcl
private_endpoints = {
  pe_kv = {
    network_configuration = {
      vnet_key   = "vnet_spoke"
      subnet_key = "snet_pe"
    }
    private_dns_zone = {
      keys = ["link_kv"]
    }
  }
}
```
The `full/` example's `main.tf` no longer needs a `key_vaults` local to merge computed subnet/DNS zone IDs — the pattern module resolves keys internally.

## Entity: vHub Connectivity Field Renames

`vhub_connectivity_definitions.virtual_network` field renamed from `id` to `resource_id` (with matching fixes in `locals.tf` and validation). Similarly, `ddos_protection_plan.id` renamed to `ddos_protection_plan.resource_id`.

## Entity: Bastion Key-Based Reference Pattern

`bastion_hosts` (map of objects) uses the same key-based reference pattern as private endpoints,
applied to two fields within each map entry:

### ip_configuration.network_configuration
Same structure as PE `network_configuration` — provides subnet via direct ID or keys:
```hcl
ip_configuration = optional(object({
  name = optional(string)
  network_configuration = object({
    subnet_resource_id = optional(string)   # Direct ID — OR use key-based:
    vnet_key           = optional(string)   # Key in virtual_networks map
    subnet_key         = optional(string)   # Key in the VNet's subnets map
  })
  create_public_ip     = optional(bool, true)
  public_ip_address_id = optional(string, null)
  # ... other ip_configuration fields ...
}))
```

### virtual_network
Matches the `vhub_connectivity_definitions.virtual_network` pattern:
```hcl
virtual_network = optional(object({
  resource_id = optional(string)  # Direct ARM resource ID
  key         = optional(string)  # Key in virtual_networks map
}))
```

### Resolution Logic (root main.tf, via locals)
- **Bastion subnet**: `coalesce(ip_configuration.network_configuration.subnet_resource_id, local.subnet_resource_ids[vnet_key][subnet_key])`
- **Bastion VNet**: `coalesce(virtual_network.resource_id, local.vnet_resource_ids[virtual_network.key])`

### Impact on Examples
The `full/` example's `terraform.tfvars` sets bastion config using keys:
```hcl
bastion_hosts = {
  bastion_full = {
    ip_configuration = {
      network_configuration = {
        vnet_key   = "vnet_spoke"
        subnet_key = "AzureBastionSubnet"
      }
      create_public_ip = false
    }
    virtual_network = {
      key = "vnet_spoke"
    }
  }
}
```
The `full/` example's `main.tf` only merges `public_ip_address_id` in the bastion locals — subnet and VNet resolution is handled by the pattern module.

## Entity: Locals Refactoring — VNet and Subnet Resource ID Lookups

Two lookup maps added to `locals.tf` for cleaner referencing, following the same
pattern as `nsg_resource_ids`, `rt_resource_ids`, and `managed_identity_principal_ids`:

```hcl
# VNet resource ID lookup: resolve vnet_key → resource ID
vnet_resource_ids = { for key, mod in module.virtual_network : key => mod.resource_id }

# Subnet resource ID lookup: resolve vnet_key → { subnet_key → resource ID }
subnet_resource_ids = { for key, mod in module.virtual_network : key => { for sk, sv in mod.subnets : sk => sv.resource_id } }
```

### Complete locals.tf Lookup Map Summary

| Local | Source Module | Shape | Used By |
|-------|--------------|-------|---------|
| `resource_group_names` | `module.resource_group` | `map(string)` | LAW, NSG, RT, MI, KV module calls |
| `resource_group_resource_ids` | `module.resource_group` | `map(string)` | VNet `parent_id`, Bastion `parent_id` |
| `vnet_resource_ids` | `module.virtual_network` | `map(string)` | DNS zone links, Bastion VNet, vHub VNet |
| `subnet_resource_ids` | `module.virtual_network` | `map(map(string))` | LAW PE, KV PE, Bastion subnet |
| `nsg_resource_ids` | `module.network_security_group` | `map(string)` | VNet subnet NSG association |
| `rt_resource_ids` | `module.route_table` | `map(string)` | VNet subnet route table association |
| `managed_identity_principal_ids` | `module.managed_identity` | `map(string)` | KV role assignments, standalone role assignments |
| `vhub_vnet_resource_ids` | derived from `vnet_resource_ids` | `map(string)` | vHub connectivity module |
| `storage_account_resource_ids` | `module.storage_account` | `map(string)` | Flow log `storage_account.key` resolution |

## Entity: Storage Account Module & Flow Log Key-Based Storage Reference

### storage_accounts Variable
```hcl
storage_accounts = optional(map(object({
  name                          = string
  resource_group_key            = string
  location                      = optional(string)
  account_tier                  = optional(string, "Standard")
  account_replication_type      = optional(string, "ZRS")
  account_kind                  = optional(string, "StorageV2")
  access_tier                   = optional(string, "Hot")
  shared_access_key_enabled     = optional(bool, false)
  public_network_access_enabled = optional(bool, false)
  https_traffic_only_enabled    = optional(bool, true)
  min_tls_version               = optional(string, "TLS1_2")
  allow_nested_items_to_be_public = optional(bool, false)
  network_rules                 = optional(object({ ... }))
  managed_identities            = optional(object({ ... }))
  containers                    = optional(map(object({ ... })))
  private_endpoints             = optional(map(object({ ... })))  # Same PE pattern + subresource_name
  role_assignments              = optional(map(object({ ... })))
  lock                          = optional(object({ ... }))
  tags                          = optional(map(string))
})), {})
```

### Flow Log Nested Object Pattern
Replaces flat `storage_account_id` with nested object; replaces `target_resource_id` with `vnet_key`:
```hcl
flow_logs = optional(map(object({
  vnet_key = string  # Key in virtual_networks map (resolved to target_resource_id)
  # ... other fields ...
  storage_account = object({
    resource_id = optional(string)  # Direct ARM resource ID — OR use key-based:
    key         = optional(string)  # Key in storage_accounts map
  })
})))
```

### Resolution Logic (root main.tf)
```hcl
target_resource_id = local.vnet_resource_ids[fl.vnet_key]
storage_account_id = coalesce(
  fl.storage_account.resource_id,
  try(local.storage_account_resource_ids[fl.storage_account.key], null)
)
```

### Validation Preconditions
1. Each flow log must set exactly one of `storage_account.resource_id` or `storage_account.key`
2. `storage_account.key` must reference a valid key in `var.storage_accounts`
3. `vnet_key` must reference a valid key in `var.virtual_networks`

### Impact on Examples
The `full/` example's `terraform.tfvars` creates the storage account via the pattern module:
```hcl
storage_accounts = {
  sa_flowlog = {
    name                     = "saflowlogfull"
    resource_group_key       = "rg_shared"
    account_replication_type = "LRS"
  }
}
```
The `full/` example's `main.tf` flow log locals reference it by key:
```hcl
storage_account = { key = "sa_flowlog" }
```
No inline `azurerm_storage_account` resource is needed — the pattern module creates the storage account and resolves the key internally.

### Network Watcher Optional Fields with Azure Standard Defaults
The `flowlog_configuration` top-level fields `network_watcher_id`, `network_watcher_name`, and `resource_group_name` are all `optional(string)` defaulting to `null`. The pattern module computes Azure standard defaults:
```hcl
resource_group_name  = coalesce(var.flowlog_configuration.resource_group_name, "NetworkWatcherRG")
network_watcher_name = coalesce(var.flowlog_configuration.network_watcher_name, "NetworkWatcher_<location>")
network_watcher_id   = coalesce(var.flowlog_configuration.network_watcher_id, "/subscriptions/<sub_id>/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_<location>")
```
Callers can override any field for non-standard Network Watcher deployments. The `full/` example no longer needs `nw_rg_name`, `nw_name`, or `nw_id` locals.

### BYO Log Analytics Workspace & Auto-Resolved Traffic Analytics
`var.log_analytics_workspace_id` (flat string) replaced with `var.byo_log_analytics_workspace`:
```hcl
byo_log_analytics_workspace = object({
  resource_id = string  # Full ARM resource ID of existing LAW
  location    = string  # Azure region of the existing LAW
})
```
`traffic_analytics` workspace fields are now `optional(string)`:
```hcl
traffic_analytics = optional(object({
  enabled               = bool
  interval_in_minutes   = optional(number)
  workspace_id          = optional(string)  # GUID — auto-resolved from LAW
  workspace_region      = optional(string)  # Region — auto-resolved from LAW
  workspace_resource_id = optional(string)  # Resource ID — auto-resolved from LAW
}))
```

### Resolution Logic (root main.tf / locals.tf)
```hcl
# locals.tf
log_analytics_workspace_resource_id = coalesce(byo.resource_id, module.law[0].resource_id)
law_workspace_id     = byo != null ? data.azurerm_log_analytics_workspace.external[0].workspace_id : module.law[0].resource.workspace_id
law_workspace_region = byo != null ? byo.location : coalesce(config.location, var.location)

# main.tf — traffic_analytics resolution
workspace_id          = coalesce(fl.traffic_analytics.workspace_id, local.law_workspace_id)
workspace_region      = coalesce(fl.traffic_analytics.workspace_region, local.law_workspace_region)
workspace_resource_id = coalesce(fl.traffic_analytics.workspace_resource_id, local.log_analytics_workspace_resource_id)
```
The `full/` example no longer needs `law_rg_name`, `law_name`, `law_resource_id` locals or the `workspace_resource_id` merge override.
