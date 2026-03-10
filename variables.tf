variable "location" {
  type        = string
  description = "The Azure region for all resources. Changing this forces recreation of all resources."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags applied to all resources that support tagging. Per-resource tags are merged on top of these. Note: vHub connections (azurerm_virtual_hub_connection) do not support tags; this variable is not passed to the vWAN connection submodule."
}

variable "use_random_suffix" {
  type        = bool
  default     = false
  description = "When true, globally-unique resources (e.g., Key Vault) receive a random suffix. Default: false (CAF names only)."
}

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

variable "resource_groups" {
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string), {})
  }))
  description = "Map of resource groups to create. The map key is used as a reference key for other resources. Location defaults to var.location if not specified."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Resource ID of an existing Log Analytics workspace. If null, the pattern auto-creates one."
}

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
      name                               = string
      remote_virtual_network_resource_id = string
      allow_forwarded_traffic            = optional(bool, true)
      allow_gateway_transit              = optional(bool, false)
      use_remote_gateways                = optional(bool, false)
      allow_virtual_network_access       = optional(bool, true)
      create_reverse_peering             = optional(bool, false)
      reverse_allow_forwarded_traffic    = optional(bool, true)
      reverse_allow_gateway_transit      = optional(bool, false)
    })), {})
    subnets = optional(map(object({
      name                       = string
      address_prefix             = optional(string)
      address_prefixes           = optional(list(string))
      network_security_group_key = optional(string)
      route_table_key            = optional(string)
      service_endpoints_with_location = optional(list(object({
        service   = string
        locations = optional(list(string), ["*"])
      })), [])
      delegations = optional(list(object({
        name = string
        service_delegation = object({
          name = string
        })
      })), [])
      default_outbound_access_enabled   = optional(bool, false)
      private_endpoint_network_policies = optional(string, "Enabled")
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
    })), {})
  }))
  default     = {}
  description = "Map of spoke virtual networks. Each entry creates a VNet with optional subnets and optional hub peerings via the AVM VNet module's peerings interface. Peerings follow the implicit map-based toggle pattern (empty map = no peering). Subnets reference NSGs and route tables by map key."

  validation {
    condition = alltrue([
      for vk, vnet in var.virtual_networks : alltrue([
        for sk, subnet in vnet.subnets : (subnet.address_prefix != null) != (subnet.address_prefixes != null)
      ])
    ])
    error_message = "Each subnet must define exactly one of address_prefix or address_prefixes, not both."
  }
}

variable "private_dns_zone_links" {
  type = map(object({
    name                 = string
    private_dns_zone_id  = string
    virtual_network_key  = string
    registration_enabled = optional(bool, false)
    resolution_policy    = optional(string, "Default")
    tags                 = optional(map(string), {})
  }))
  default     = {}
  description = "Map of Private DNS Zone VNet links. Each links an existing DNS zone (by resource ID) to a spoke VNet (by map key). Uses avm-res-network-privatednszone submodule private_dns_virtual_network_link."
}

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

  validation {
    condition = alltrue([
      for kv_key, kv in var.key_vaults : alltrue([
        for ra_key, ra in kv.role_assignments : (ra.principal_id != null) != (ra.managed_identity_key != null)
      ])
    ])
    error_message = "Each Key Vault role assignment must set exactly one of principal_id or managed_identity_key."
  }
}

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

  validation {
    condition     = alltrue([for k, ra in var.role_assignments : (ra.principal_id != null) != (ra.managed_identity_key != null)])
    error_message = "Each standalone role assignment must set exactly one of principal_id or managed_identity_key."
  }
}

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

variable "bastion_configuration" {
  type = object({
    name               = optional(string)
    resource_group_key = string
    location           = optional(string)
    sku                = optional(string, "Standard")
    zones              = optional(set(string), ["1", "2", "3"])
    ip_configuration = optional(object({
      name                             = optional(string)
      subnet_id                        = string
      create_public_ip                 = optional(bool, true)
      public_ip_tags                   = optional(map(string), null)
      public_ip_merge_with_module_tags = optional(bool, true)
      public_ip_address_name           = optional(string, null)
      public_ip_address_id             = optional(string, null)
    }))
    virtual_network_id        = optional(string)
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
  })
  default     = null
  description = <<-EOT
    Bastion host configuration. When non-null, deploys an Azure Bastion Host (implicit toggle — null = no Bastion).
    All AVM bastion module variables are exposed — see https://registry.terraform.io/modules/Azure/avm-res-network-bastionhost/azurerm.
    For non-Developer SKUs, ip_configuration is required with subnet_id pointing to an AzureBastionSubnet (minimum /26).
    For Developer SKU, set virtual_network_id instead and omit ip_configuration.
    SKU defaults to 'Standard'. Zones default to ["1","2","3"] (zone-redundant).
  EOT
}

# ──────────────────────────────────────────────────────────────
# Network Watcher / Flow Logs
# ──────────────────────────────────────────────────────────────

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
