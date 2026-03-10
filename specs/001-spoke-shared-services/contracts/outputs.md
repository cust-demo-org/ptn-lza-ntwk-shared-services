# Output Contract: ALZ Spoke Networking & Shared Services Pattern

**Branch**: `001-spoke-shared-services` | **Date**: 2026-03-09
**File**: `outputs.tf`

This document defines the public output contract for the pattern's root module. Downstream consumers (application landing zone patterns, workload modules) depend on these outputs.

---

## Resource Group Outputs

```hcl
output "resource_groups" {
  value       = { for key, mod in module.resource_group : key => {
    resource_id = mod.resource_id
    name        = mod.name
  }}
  description = "Map of resource group keys to their resource IDs and names."
}
```

---

## Virtual Network Outputs

```hcl
output "virtual_networks" {
  value       = { for key, mod in module.virtual_network : key => {
    resource_id    = mod.resource_id
    name           = mod.name
    address_spaces = mod.address_spaces
    subnets        = mod.subnets
    peerings       = mod.peerings
  }}
  description = "Map of VNet keys to their resource IDs, names, address spaces, subnet details, and peering details."
}
```

---

## Network Security Group Outputs

```hcl
output "network_security_groups" {
  value       = { for key, mod in module.network_security_group : key => {
    resource_id = mod.resource_id
    name        = mod.name
  }}
  description = "Map of NSG keys to their resource IDs and names."
}
```

---

## Route Table Outputs

```hcl
output "route_tables" {
  value       = { for key, mod in module.route_table : key => {
    resource_id = mod.resource_id
    name        = mod.name
  }}
  description = "Map of route table keys to their resource IDs and names."
}
```

---

## Private DNS Zone Link Outputs

```hcl
output "private_dns_zone_links" {
  value       = { for key, mod in module.private_dns_zone_link : key => {
    resource_id = mod.resource_id
    name        = mod.resource.name
  }}
  description = "Map of Private DNS Zone VNet link keys to their resource IDs and names."
}
```

---

## Managed Identity Outputs

```hcl
output "managed_identities" {
  value       = { for key, mod in module.managed_identity : key => {
    resource_id  = mod.resource_id
    name         = mod.name
    principal_id = mod.principal_id
    client_id    = mod.client_id
  }}
  description = "Map of managed identity keys to their resource IDs, names, principal IDs, and client IDs."
}
```

---

## Key Vault Outputs

```hcl
output "key_vaults" {
  value       = { for key, mod in module.key_vault : key => {
    resource_id = mod.resource_id
    name        = mod.name
    uri         = mod.uri
  }}
  description = "Map of Key Vault keys to their resource IDs, names, and URIs."
}
```

---

## Bastion Outputs

```hcl
output "bastion" {
  value = var.bastion_configuration != null ? {
    resource_id = module.bastion_host[0].resource_id
    name        = module.bastion_host[0].name
  } : null
  description = "Bastion host resource ID and name. Null when Bastion is not enabled."
}
```

---

## Network Watcher Outputs

```hcl
output "network_watcher" {
  value = var.flowlog_configuration != null ? {
    resource_id = module.network_watcher[0].resource_id
    flow_logs   = module.network_watcher[0].resource_flow_log
  } : null
  description = "Network Watcher resource ID and flow log details. Null when flowlog_configuration is not provided."
}
```

---

## Role Assignment Outputs

```hcl
output "role_assignments" {
  value = {
    for key, mod in module.role_assignment : key => {
      resource_id = mod.resource_id
    }
  }
  description = "Map of standalone role assignment keys to their resource IDs. Empty map when no standalone role assignments are configured."
}
```

---

## Log Analytics Workspace Outputs

```hcl
output "log_analytics_workspace" {
  value = {
    resource_id = local.log_analytics_workspace_id
    name        = split("/", local.log_analytics_workspace_id)[length(split("/", local.log_analytics_workspace_id)) - 1]
  }
  description = "Log Analytics workspace resource ID and name (auto-created or externally provided). Name is derived from the resource ID."
}
```

---

## Virtual Hub Connection Outputs

```hcl
output "vhub_connections" {
  value = {
    for k, v in module.vnet_conn : k => {
      resource_id = v.resource_id
    }
  }
  description = "Map of Virtual Hub VNet connections, keyed by vhub_connectivity_definitions map key. Empty map when no vWAN connections are configured."
}
```

---

## Design Notes

1. **Consistent shape**: Every output map uses `resource_id` and `name` as the minimum fields. Additional fields are added where consumers commonly need them (e.g., `principal_id` for managed identities, `uri` for Key Vault).

2. **Map keys preserved**: Output map keys match the input variable map keys, enabling consumers to look up resources by the same logical names they used when configuring the pattern.

3. **Empty map for disabled features**: Optional map-based features (vWAN connections, standalone role assignments) output empty maps `{}` when disabled, consistent with the implicit map-based toggle pattern. Boolean-toggled features (Bastion) and implicit-toggle features (Network Watcher) output `null` when disabled.

4. **No sensitive outputs**: Resource IDs and names are not sensitive. Secrets (Key Vault values) are never exposed as outputs.

5. **terraform-docs compatibility**: All outputs have `description` attributes. The `outputs.tf` file will have `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers in the README for auto-generation.
