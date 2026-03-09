# Variable Contract: ALZ Spoke Networking & Shared Services Pattern

**Branch**: `001-spoke-shared-services` | **Date**: 2026-03-09
**File**: `variables.tf`

This document defines the public input variable contract for the pattern's root module. All consumers interact exclusively via `terraform.tfvars`.

---

## Global Variables

### `location`

```hcl
variable "location" {
  type        = string
  description = "The Azure region for all resources. Changing this forces recreation of all resources."
}
```

### `tags`

```hcl
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags applied to all resources. Per-resource tags are merged on top of these."
}
```

### `use_random_suffix`

```hcl
variable "use_random_suffix" {
  type        = bool
  default     = false
  description = "When true, globally-unique resources (e.g., Key Vault) receive a random suffix. Default: false (CAF names only)."
}
```

### `lock`

```hcl
variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = "Resource lock applied to all resources via AVM module lock interfaces. Set to null to disable. Possible kind values: 'CanNotDelete', 'ReadOnly'."

  validation {
    condition     = var.lock == null || contains(["CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "lock.kind must be 'CanNotDelete' or 'ReadOnly'."
  }
}
```

---

## Connectivity Variables

### `connectivity_mode`

```hcl
variable "connectivity_mode" {
  type        = string
  default     = "none"
  description = "Hub connectivity mode. 'none' = isolated spoke, 'hub_peering' = VNet peering to a hub VNet, 'vwan' = connection to a Virtual WAN hub."

  validation {
    condition     = contains(["none", "hub_peering", "vwan"], var.connectivity_mode)
    error_message = "connectivity_mode must be one of: 'none', 'hub_peering', 'vwan'."
  }
}
```

### `hub_virtual_network_id`

```hcl
variable "hub_virtual_network_id" {
  type        = string
  default     = null
  description = "Resource ID of the hub VNet. Required when connectivity_mode = 'hub_peering'. Ignored otherwise."
}
```

### `enable_hub_side_peering`

```hcl
variable "enable_hub_side_peering" {
  type        = bool
  default     = false
  description = "When true and connectivity_mode = 'hub_peering', creates the hub-to-spoke reverse peering. Requires write access to the hub VNet."
}
```

### `hub_peering_options`

```hcl
variable "hub_peering_options" {
  type = object({
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
  })
  default     = {}
  description = "Advanced peering options when connectivity_mode = 'hub_peering'. AVM module defaults apply for any omitted field."
}
```

### `virtual_hub_id`

```hcl
variable "virtual_hub_id" {
  type        = string
  default     = null
  description = "Resource ID of the Virtual WAN Hub. Required when connectivity_mode = 'vwan'. Ignored otherwise."
}
```

### `virtual_hub_connection_internet_security_enabled`

```hcl
variable "virtual_hub_connection_internet_security_enabled" {
  type        = bool
  default     = true
  description = "When true and connectivity_mode = 'vwan', routes internet traffic through the hub firewall. Default: true (secure-by-default)."
}
```

---

## Resource Group Variables

### `resource_groups`

```hcl
variable "resource_groups" {
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string), {})
  }))
  description = "Map of resource groups to create. The map key is used as a reference key for other resources. Location defaults to var.location if not specified."
}
```

---

## Virtual Network Variables

### `virtual_networks`

```hcl
variable "virtual_networks" {
  type = map(object({
    name               = string
    address_space      = set(string)
    resource_group_key = string
    location           = optional(string)
    dns_servers        = optional(list(string))
    ddos_protection_plan = optional(object({
      id     = string
      enable = bool
    }))
    encryption = optional(object({
      enabled     = bool
      enforcement = string
    }))
    tags = optional(map(string), {})
    subnets = optional(map(object({
      name                                = string
      address_prefix                      = optional(string)
      address_prefixes                    = optional(list(string))
      network_security_group_key          = optional(string)
      route_table_key                     = optional(string)
      service_endpoints_with_location     = optional(list(object({
        service   = string
        locations = optional(list(string), ["*"])
      })), [])
      delegations = optional(list(object({
        name = string
        service_delegation = object({
          name = string
        })
      })), [])
      default_outbound_access_enabled     = optional(bool, false)
      private_endpoint_network_policies   = optional(string, "Enabled")
      role_assignments                    = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = string
        description                            = optional(string, null)
        skip_service_principal_aad_check       = optional(bool, false)
        condition                              = optional(string, null)
        condition_version                      = optional(string, null)
        delegated_managed_identity_resource_id = optional(string, null)
        principal_type                         = optional(string, null)
      })), {})
    })), {})
  }))
  description = "Map of spoke virtual networks. Each entry creates a VNet with optional subnets. Subnets reference NSGs and route tables by map key."
}
```

---

## Network Security Group Variables

### `network_security_groups`

```hcl
variable "network_security_groups" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    security_rules = optional(map(object({
      name                                       = string
      priority                                   = number
      direction                                  = string
      access                                     = string
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(set(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(set(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(set(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(set(string))
      source_application_security_group_ids      = optional(set(string))
      destination_application_security_group_ids = optional(set(string))
      description                                = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = "Map of NSGs. A DenyAllInbound rule (priority 4096) is always injected. Additional rules are merged from security_rules."
}
```

---

## Route Table Variables

### `route_tables`

```hcl
variable "route_tables" {
  type = map(object({
    name                          = string
    resource_group_key            = string
    location                      = optional(string)
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = "Map of route tables. Each can contain multiple routes. Associate to subnets via the subnet's route_table_key."
}
```

---

## Private DNS Zone Link Variables

### `private_dns_zone_links`

```hcl
variable "private_dns_zone_links" {
  type = map(object({
    private_dns_zone_id  = string
    virtual_network_key  = string
    registration_enabled = optional(bool, false)
    resolution_policy    = optional(string, "Default")
    tags                 = optional(map(string), {})
  }))
  default     = {}
  description = "Map of Private DNS Zone VNet links. Each links an existing DNS zone (by resource ID) to a spoke VNet (by map key). Uses avm-res-network-privatednszone submodule private_dns_virtual_network_link."
}
```

---

## Managed Identity Variables

### `managed_identities`

```hcl
variable "managed_identities" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    tags               = optional(map(string), {})
  }))
  default     = {}
  description = "Map of user-assigned managed identities to create."
}
```

---

## Key Vault Variables

### `key_vaults`

```hcl
variable "key_vaults" {
  type = map(object({
    name                          = string
    resource_group_key            = string
    location                      = optional(string)
    sku_name                      = optional(string, "premium")
    public_network_access_enabled = optional(bool, false)
    purge_protection_enabled      = optional(bool, true)
    soft_delete_retention_days    = optional(number, null)
    network_acls = optional(object({
      bypass                     = optional(string, "None")
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = optional(string)
      managed_identity_key       = optional(string)
      description                = optional(string, null)
      principal_type             = optional(string, null)
    })), {})
    private_endpoints = optional(map(object({
      name                          = optional(string, null)
      subnet_resource_id            = string
      private_dns_zone_resource_ids = optional(set(string), [])
      tags                          = optional(map(string), null)
    })), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    Map of Key Vaults. public_network_access_enabled defaults to false (secure-by-default, overrides AVM default of true).
    Role assignments support the resource reference pattern: provide principal_id directly OR managed_identity_key to resolve from the managed_identities map.
  EOT
}
```

---

## Bastion Variables

### `enable_bastion`

```hcl
variable "enable_bastion" {
  type        = bool
  default     = false
  description = "When true, deploys Azure Bastion into the AzureBastionSubnet of the first VNet. Default: false."
}
```

### `bastion_configuration`

```hcl
variable "bastion_configuration" {
  type = object({
    name               = optional(string)
    virtual_network_key = string
    resource_group_key = string
    sku                = optional(string, "Standard")
    location           = optional(string)
    zones              = optional(set(string), ["1", "2", "3"])
    tags               = optional(map(string), {})
  })
  default     = null
  description = <<-EOT
    Bastion configuration. Required when enable_bastion = true.
    The specified virtual_network must contain an 'AzureBastionSubnet'.
    SKU defaults to 'Standard' which supports zone-redundancy. Zones default to all three.
  EOT
}
```

---

## Diagnostics Variables

### `log_analytics_workspace_id`

```hcl
variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Resource ID of an existing Log Analytics workspace. If null, the pattern auto-creates one."
}
```

### `log_analytics_workspace_configuration`

```hcl
variable "log_analytics_workspace_configuration" {
  type = object({
    name               = optional(string)
    resource_group_key = string
    location           = optional(string)
    sku                = optional(string, "PerGB2018")
    retention_in_days  = optional(number, 30)
    tags               = optional(map(string), {})
  })
  default     = null
  description = "Configuration for the auto-created Log Analytics workspace. Used only when log_analytics_workspace_id is null."
}
```

---

## Role Assignment Variables

### `role_assignments`

```hcl
variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name = string
    scope                      = string
    principal_id               = optional(string)
    managed_identity_key       = optional(string)
    description                = optional(string, null)
    principal_type             = optional(string, null)
  }))
  default     = {}
  description = <<-EOT
    Standalone role assignments at arbitrary scopes (not scoped to an AVM-managed resource).
    Uses avm-res-authorization-roleassignment module.
    principal_id or managed_identity_key must be provided (resource reference pattern applies).
  EOT
}
```

---

## Validation Rules Summary

| Variable | Rule | Error Message |
|---|---|---|
| `connectivity_mode` | Must be `none`, `hub_peering`, or `vwan` | "connectivity_mode must be one of: 'none', 'hub_peering', 'vwan'." |
| `hub_virtual_network_id` | Must be non-null when `connectivity_mode = "hub_peering"` | Precondition on VNet peering |
| `virtual_hub_id` | Must be non-null when `connectivity_mode = "vwan"` | Precondition on vWAN connection |
| `enable_bastion` + `bastion_configuration` | `bastion_configuration` must be non-null when `enable_bastion = true` | Precondition on Bastion module |
| `lock.kind` | Must be `CanNotDelete` or `ReadOnly` | Variable validation block |
| Key Vault `role_assignments` | At least one of `principal_id` or `managed_identity_key` must be set | Precondition |
