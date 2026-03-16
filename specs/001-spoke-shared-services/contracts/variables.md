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

## Private DNS Zone Variables

### `private_dns_zones`

```hcl
variable "private_dns_zones" {
  type = map(object({
    domain_name        = string
    resource_group_key = string
    virtual_network_links = optional(map(object({
      name                 = string
      virtual_network_key  = string
      registration_enabled = optional(bool, false)
      resolution_policy    = optional(string, "Default")
      tags                 = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = "Map of Private DNS Zones to create and optionally link to VNets. For BYO zones, use byo_private_dns_zone_links."
}
```

---

## BYO Private DNS Zone Link Variables

### `byo_private_dns_zone_links`

```hcl
variable "byo_private_dns_zone_links" {
  type = map(object({
    private_dns_zone_id  = string
    virtual_network_key  = string
    registration_enabled = optional(bool, false)
    resolution_policy    = optional(string, "Default")
    tags                 = optional(map(string), {})
  }))
  default     = {}
  description = "Map of BYO (Bring Your Own) Private DNS Zone VNet links. Each links an existing DNS zone (by resource ID) to a spoke VNet (by map key). Uses avm-res-network-privatednszone submodule private_dns_virtual_network_link. For creating new DNS zones, use private_dns_zones instead."
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

### `bastion_hosts`

```hcl
variable "bastion_hosts" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    sku                = optional(string, "Standard")
    zones              = optional(set(string), ["1", "2", "3"])
    ip_configuration = optional(object({
      name = optional(string)
      network_configuration = object({
        subnet_resource_id = optional(string)
        vnet_key           = optional(string)
        subnet_key         = optional(string)
      })
      create_public_ip                 = optional(bool, true)
      public_ip_tags                   = optional(map(string), null)
      public_ip_merge_with_module_tags = optional(bool, true)
      public_ip_address_name           = optional(string, null)
      public_ip_address_id             = optional(string, null)
    }))
    virtual_network = optional(object({
      resource_id = optional(string)
      key         = optional(string)
    }))
    copy_paste_enabled        = optional(bool, true)
    file_copy_enabled         = optional(bool, false)
    ip_connect_enabled        = optional(bool, false)
    kerberos_enabled          = optional(bool, false)
    private_only_enabled      = optional(bool, false)
    scale_units               = optional(number, 2)
    session_recording_enabled = optional(bool, false)
    shareable_link_enabled    = optional(bool, false)
    tunneling_enabled         = optional(bool, false)
    tags                      = optional(map(string), {})
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
  }))
  default     = {}
  description = <<-EOT
    Map of Azure Bastion Host configurations, keyed by a user-chosen identifier.
    Empty map = no Bastion hosts deployed.
    All AVM bastion module variables are exposed — see https://registry.terraform.io/modules/Azure/avm-res-network-bastionhost/azurerm.
    For non-Developer SKUs, ip_configuration is required with subnet via network_configuration (direct ID or vnet_key/subnet_key referencing an AzureBastionSubnet, minimum /26).
    For Developer SKU, set virtual_network instead and omit ip_configuration.
    SKU defaults to 'Standard'. Zones default to ["1","2","3"] (zone-redundant).
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

## Network Watcher Variables

### `flowlog_configuration`

```hcl
variable "flowlog_configuration" {
  type = object({
    network_watcher_id   = string
    network_watcher_name = string
    resource_group_name  = string
    location             = optional(string)
    flow_logs = optional(map(object({
      enabled            = bool
      name               = string
      target_resource_id = string
      retention_policy = object({
        days    = number
        enabled = bool
      })
      storage_account_id = string
      traffic_analytics = optional(object({
        enabled               = bool
        interval_in_minutes   = optional(number)
        workspace_id          = string
        workspace_region      = string
        workspace_resource_id = string
      }))
      version = optional(number)
    })), null)
    tags = optional(map(string), {})
  })
  default     = null
  description = <<-EOT
    Configuration for Network Watcher VNet flow logs using the AVM network watcher module (avm-res-network-networkwatcher v0.3.2).
    When null (default), no Network Watcher or flow logs are configured.
    The network_watcher_id, network_watcher_name, and resource_group_name reference the existing Network Watcher
    (typically auto-created by Azure per region per subscription).
    flow_logs defines VNet flow log configurations passed through to the AVM module.
    All settings are consumer-defined; the pattern does not auto-configure any flow log settings.
  EOT
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
| _(removed — `enable_bastion` eliminated; `bastion_hosts` non-empty map is the implicit toggle)_ | | |
| `lock.kind` | Must be `CanNotDelete` or `ReadOnly` | Variable validation block |
| Key Vault `role_assignments` | Exactly one of `principal_id` or `managed_identity_key` must be set | Precondition |
| `virtual_networks[*].subnets[*]` | Exactly one of `address_prefix` or `address_prefixes` must be set (mutually exclusive) | "Each subnet must define exactly one of address_prefix or address_prefixes, not both." |
| `bastion_hosts[*].ip_configuration.subnet_id` | For non-Developer SKUs, `ip_configuration` must be provided with a valid AzureBastionSubnet ID (minimum /26). For Developer SKU, `virtual_network_id` must be provided instead. | AVM module built-in validation |
| `log_analytics_workspace_id` + `log_analytics_workspace_configuration` | When `log_analytics_workspace_id` is null, `log_analytics_workspace_configuration` must be non-null (FR-028) | "log_analytics_workspace_configuration must be provided when log_analytics_workspace_id is null, so that a Log Analytics workspace can be auto-created." |
| Standalone `role_assignments[*]` | Exactly one of `principal_id` or `managed_identity_key` must be set | "Each standalone role assignment must set exactly one of principal_id or managed_identity_key." |
| Standalone `role_assignments[*].managed_identity_key` | When set, must exist as a key in `var.managed_identities` | "Standalone role assignment references managed_identity_key '{key}' which does not exist in managed_identities." |
| Key Vault `role_assignments[*].managed_identity_key` | When set, must exist as a key in `var.managed_identities` | "Key Vault role assignment references managed_identity_key '{key}' which does not exist in managed_identities." |
| `private_dns_zones[*].virtual_network_links[*].virtual_network_key` | Must exist as a key in `var.virtual_networks` | "DNS zone virtual_network_link references virtual_network_key '{key}' which does not exist in virtual_networks." |
| `byo_private_dns_zone_links[*].virtual_network_key` | Must exist as a key in `var.virtual_networks` | "BYO DNS zone link references virtual_network_key '{key}' which does not exist in virtual_networks." |
