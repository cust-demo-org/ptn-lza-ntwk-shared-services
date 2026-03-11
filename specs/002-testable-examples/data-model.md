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
| `use_random_suffix` | ❌ | ❌ | ❌ | ✅ | `false` |
| `lock` | ❌ | ❌ | ❌ | ✅ | `null` |
| `resource_groups` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `log_analytics_workspace_id` | ❌ | ❌ | ❌ | ❌ | `null` |
| `log_analytics_workspace_configuration` | ✅ | ✅ | ✅ | ✅ | `null` |
| `network_security_groups` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `route_tables` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `virtual_networks` | ✅ | ✅ | ✅ | ✅ | `{}` |
| `private_dns_zone_links` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `managed_identities` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `key_vaults` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `role_assignments` | ❌ | ❌ | ❌ | ✅ | `{}` |
| `vhub_connectivity_definitions` | ❌ | ❌ | ✅ | ❌ | `{}` |
| `bastion_configuration` | ❌ | ❌ | ❌ | ✅ | `null` |
| `flowlog_configuration` | ❌ | ❌ | ❌ | ✅ | `null` |

Legend: ✅ = overridden in terraform.tfvars, ❌ = uses default (feature not exercised in this example)

## Entity: Inline Dependency Model

Resources deployed directly in `main.tf` per example (NOT through the pattern module).

### minimal/
```
azurerm_resource_group — NO (created by pattern module via resource_groups var)
module "naming" (Azure/naming/azurerm) — unique names
module "pattern" (source = "../..") — the module under test
```

### vnet_hub/
```
module "naming"
azurerm_resource_group — hub RG (separate from spoke)
azurerm_virtual_network — hub VNet (peering target)
module "pattern"
```

### vwan_hub/
```
module "naming"
azurerm_resource_group — connectivity RG
azurerm_virtual_wan
azurerm_virtual_hub
module "pattern"
```

### full/
```
module "naming"
azurerm_resource_group — hub/connectivity RG
azurerm_virtual_network — hub VNet (peering target)
azurerm_private_dns_zone — for private_dns_zone_links
azurerm_public_ip — for Bastion
azurerm_storage_account — for flow log storage
module "pattern"
```

**Note**: The hub resource group is created inline only for examples that need external dependencies (hub VNet, vWAN, etc.). The spoke's resource groups are created by the pattern module itself.

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

### bastion_configuration
```hcl
# ADD:
role_assignments = optional(map(object({ ... })), {})
```

### virtual_networks (VNet-level)
```hcl
# ADD:
role_assignments = optional(map(object({ ... })), {})  # At VNet level, not just subnet level
```
