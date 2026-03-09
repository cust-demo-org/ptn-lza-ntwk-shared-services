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
  description = "Common tags applied to all resources that support tagging. Per-resource tags are merged on top of these. Note: vHub connections (azurerm_virtual_hub_connection) do not support tags; this variable is not passed to the vWAN connection submodule."
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
  description = "Resource lock applied to AVM root-module resources that expose the lock interface (resource group, VNet, NSG, route table, Key Vault, Bastion, Log Analytics workspace, managed identity). Does not apply to AVM submodule resources (DNS zone VNet links, vHub connections) as those submodules do not implement the lock interface. Set to null to disable. Possible kind values: 'CanNotDelete', 'ReadOnly'."

  validation {
    condition     = var.lock == null || contains(["CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "lock.kind must be 'CanNotDelete' or 'ReadOnly'."
  }
}
```

---

## Connectivity Variables

> **Design Note**: Hub VNet peering is configured per-VNet via the AVM VNet module's `peerings` map within `virtual_networks`. The standalone `connectivity_mode`, `hub_virtual_network_id`, `enable_hub_side_peering`, and `hub_peering_options` variables have been removed. See `virtual_networks[*].peerings` for hub peering configuration.

### `vhub_connectivity_definitions`

```hcl
variable "vhub_connectivity_definitions" {
  type = map(object({
    vhub_resource_id = string
    virtual_network = object({
      key = optional(string)
      id  = optional(string)
    })
    internet_security_enabled = optional(bool, true)
  }))
  default     = {}
  description = "Map of vWAN hub connections. Each entry links a spoke VNet to a vWAN hub. Reference the VNet by key (from virtual_networks map) or by resource ID. Empty map = no vWAN connections (implicit toggle). Default internet_security_enabled = true (secure-by-default, routes internet traffic through the hub firewall)."

  validation {
    condition     = alltrue([for k, v in var.vhub_connectivity_definitions : (v.virtual_network.key != null) != (v.virtual_network.id != null)])
    error_message = "Each vhub_connectivity_definition must set exactly one of virtual_network.key or virtual_network.id."
  }
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
    peerings = optional(map(object({
      name                                = string
      remote_virtual_network_resource_id  = string
      allow_forwarded_traffic             = optional(bool, true)
      allow_gateway_transit               = optional(bool, false)
      use_remote_gateways                 = optional(bool, false)
      allow_virtual_network_access        = optional(bool, true)
      create_reverse_peering              = optional(bool, false)
      reverse_allow_forwarded_traffic     = optional(bool, true)
      reverse_allow_gateway_transit       = optional(bool, false)
    })), {})
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
  description = "Map of spoke virtual networks. Each entry creates a VNet with optional subnets and optional hub peerings via the AVM VNet module's peerings interface. Peerings follow the implicit map-based toggle pattern (empty map = no peering). Subnets reference NSGs and route tables by map key."
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
  description = "Map of NSGs. All security rules are user-defined via the security_rules map. An empty security_rules = {} means only Azure built-in default rules apply. No rules are auto-injected."
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
    Role assignments support two principal reference modes: principal_id accepts the direct principal ID of any identity (MSI, service principal, users); managed_identity_key references a key in the managed_identities map (for identities created within this pattern). Exactly one must be set.
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
    principal_id accepts the direct principal ID of any identity (MSI, service principal, users).
    managed_identity_key references a key in the managed_identities map (for identities created within this pattern).
    Exactly one must be set.
  EOT
}
```

---

## Validation Rules Summary

| Variable | Rule | Error Message |
|---|---|---|
| `vhub_connectivity_definitions[*]` | Each entry must set exactly one of `virtual_network.key` or `virtual_network.id` | "Each vhub_connectivity_definition must set exactly one of virtual_network.key or virtual_network.id." |
| `enable_bastion` + `bastion_configuration` | `bastion_configuration` must be non-null when `enable_bastion = true` | Precondition on Bastion module |
| `lock.kind` | Must be `CanNotDelete` or `ReadOnly` | Variable validation block |
| Key Vault `role_assignments` | Exactly one of `principal_id` or `managed_identity_key` must be set | Precondition |
| `virtual_networks[*].subnets[*]` | Exactly one of `address_prefix` or `address_prefixes` must be set (mutually exclusive) | "Each subnet must define exactly one of address_prefix or address_prefixes, not both." |
| `enable_bastion` + `bastion_configuration.virtual_network_key` | The referenced VNet must contain a subnet named `AzureBastionSubnet` | "Bastion is enabled but the VNet referenced by bastion_configuration.virtual_network_key does not contain an 'AzureBastionSubnet'." |
| Key Vault `role_assignments[*].managed_identity_key` | When set, must exist as a key in `var.managed_identities` | "Key Vault role assignment references managed_identity_key '{key}' which does not exist in managed_identities." |
| `private_dns_zone_links[*].virtual_network_key` | Must exist as a key in `var.virtual_networks` | "DNS zone link references virtual_network_key '{key}' which does not exist in virtual_networks." |
