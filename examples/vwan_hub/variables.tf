variable "location" {
  type        = string
  default     = "southeastasia"
  description = "Azure region for all resources. Refer to the main pattern module variable descriptions for complete details."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources. Refer to the main pattern module variable descriptions for complete details."
}

variable "use_random_suffix" {
  type        = bool
  default     = false
  description = "When true, globally-unique resources receive a random suffix. Refer to the main pattern module variable descriptions for complete details."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = "Resource lock applied to supported resources. Null disables. Refer to the main pattern module variable descriptions for complete details."
}

variable "resource_groups" {
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
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
  description = "Map of resource groups to create. Refer to the main pattern module variable descriptions for complete details."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Resource ID of an existing Log Analytics workspace. Null auto-creates one. Refer to the main pattern module variable descriptions for complete details."
}

variable "log_analytics_workspace_configuration" {
  type = object({
    name               = optional(string)
    resource_group_key = string
    location           = optional(string)
    sku                = optional(string, "PerGB2018")
    retention_in_days  = optional(number, 30)
    tags               = optional(map(string), {})
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
    private_endpoints = optional(map(object({
      name                          = optional(string, null)
      subnet_resource_id            = string
      private_dns_zone_resource_ids = optional(set(string), [])
      tags                          = optional(map(string), null)
    })), {})
  })
  default     = null
  description = "Configuration for auto-created Log Analytics workspace. Refer to the main pattern module variable descriptions for complete details."
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
  description = "Map of Network Security Groups. Refer to the main pattern module variable descriptions for complete details."
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
  description = "Map of route tables. Refer to the main pattern module variable descriptions for complete details."
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
  description = "Map of spoke virtual networks with subnets and optional peerings. Refer to the main pattern module variable descriptions for complete details."
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
  description = "Map of Private DNS Zone VNet links. Refer to the main pattern module variable descriptions for complete details."
}

variable "managed_identities" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    tags               = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      scope                                  = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, null)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  }))
  default     = {}
  description = "Map of user-assigned managed identities. Refer to the main pattern module variable descriptions for complete details."
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
  description = "Map of Key Vaults. Refer to the main pattern module variable descriptions for complete details."
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
  description = "Standalone role assignments at arbitrary scopes. Refer to the main pattern module variable descriptions for complete details."
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
  description = "Map of vWAN hub connections linking spoke VNets to a Virtual Hub. Refer to the main pattern module variable descriptions for complete details."
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
  })
  default     = null
  description = "Bastion host configuration. Null disables Bastion. Refer to the main pattern module variable descriptions for complete details."
}

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
  description = "Network Watcher flow log configuration. Null disables flow logs. Refer to the main pattern module variable descriptions for complete details."
}
