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

variable "byo_log_analytics_workspace" {
  type = object({
    resource_id = string
    location    = string
  })
  default     = null
  description = "Bring-your-own Log Analytics workspace. Null auto-creates one. Refer to the main pattern module variable descriptions for complete details."
}

variable "log_analytics_workspace_configuration" {
  type = object({
    name                               = string
    resource_group_key                 = string
    location                           = optional(string)
    sku                                = optional(string, "PerGB2018")
    retention_in_days                  = optional(number, 30)
    daily_quota_gb                     = optional(number)
    internet_ingestion_enabled         = optional(bool)
    internet_query_enabled             = optional(bool)
    local_authentication_enabled       = optional(bool, true)
    allow_resource_only_permissions    = optional(bool)
    cmk_for_query_forced               = optional(bool)
    dedicated_cluster_resource_id      = optional(string)
    reservation_capacity_in_gb_per_day = optional(number)
    identity = optional(object({
      type         = string
      identity_ids = optional(set(string))
    }))
    customer_managed_key = optional(object({
      key_vault_resource_id = string
      key_name              = string
      key_version           = optional(string)
      user_assigned_identity = optional(object({
        resource_id = string
      }))
    }))
    data_exports = optional(map(object({
      name                    = string
      table_names             = list(string)
      destination_resource_id = string
      enabled                 = optional(bool, true)
      event_hub_name          = optional(string)
    })), {})
    linked_storage_accounts = optional(map(object({
      data_source_type    = string
      storage_account_ids = list(string)
    })), {})
    tables = optional(map(object({
      name                    = string
      resource_id             = optional(string)
      retention_in_days       = optional(number)
      total_retention_in_days = optional(number)
      plan                    = optional(string)
      schema = optional(object({
        name        = optional(string)
        description = optional(string)
        columns = optional(list(object({
          name = string
          type = string
        })), [])
      }))
    })), {})
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
    tags = optional(map(string), {})
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
    private_endpoints = optional(map(object({
      name = optional(string, null)
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
      lock = optional(object({
        kind = string
        name = optional(string, null)
      }), null)
      network_configuration = object({
        subnet_resource_id = optional(string)
        vnet_key           = optional(string)
        subnet_key         = optional(string)
      })
      private_dns_zone = optional(object({
        resource_ids = optional(set(string))
        keys         = optional(set(string))
      }))
      private_dns_zone_group_name             = optional(string, "default")
      application_security_group_associations = optional(map(string), {})
      private_service_connection_name         = optional(string, null)
      network_interface_name                  = optional(string, null)
      location                                = optional(string, null)
      resource_group_name                     = optional(string, null)
      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
      })), {})
      tags = optional(map(string), null)
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
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
      use_default_log_analytics                = optional(bool, true)
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
      resource_id = string
      enable      = bool
    }))
    encryption = optional(object({
      enabled     = bool
      enforcement = string
    }))
    bgp_community           = optional(string)
    enable_vm_protection    = optional(bool, false)
    flow_timeout_in_minutes = optional(number)
    ipam_pools = optional(list(object({
      id            = string
      prefix_length = number
    })))
    tags = optional(map(string), {})
    peerings = optional(map(object({
      name                               = string
      remote_virtual_network_resource_id = string
      allow_forwarded_traffic            = optional(bool, true)
      allow_gateway_transit              = optional(bool, false)
      allow_virtual_network_access       = optional(bool, true)
      do_not_verify_remote_gateways      = optional(bool, false)
      enable_only_ipv6_peering           = optional(bool, false)
      peer_complete_vnets                = optional(bool, true)
      local_peered_address_spaces = optional(list(object({
        address_prefix = string
      })))
      remote_peered_address_spaces = optional(list(object({
        address_prefix = string
      })))
      local_peered_subnets = optional(list(object({
        subnet_name = string
      })))
      remote_peered_subnets = optional(list(object({
        subnet_name = string
      })))
      use_remote_gateways                   = optional(bool, false)
      create_reverse_peering                = optional(bool, false)
      reverse_name                          = optional(string)
      reverse_allow_forwarded_traffic       = optional(bool, true)
      reverse_allow_gateway_transit         = optional(bool, false)
      reverse_allow_virtual_network_access  = optional(bool, true)
      reverse_do_not_verify_remote_gateways = optional(bool, false)
      reverse_enable_only_ipv6_peering      = optional(bool, false)
      reverse_peer_complete_vnets           = optional(bool, true)
      reverse_local_peered_address_spaces = optional(list(object({
        address_prefix = string
      })))
      reverse_remote_peered_address_spaces = optional(list(object({
        address_prefix = string
      })))
      reverse_local_peered_subnets = optional(list(object({
        subnet_name = string
      })))
      reverse_remote_peered_subnets = optional(list(object({
        subnet_name = string
      })))
      reverse_use_remote_gateways        = optional(bool, false)
      sync_remote_address_space_enabled  = optional(bool, false)
      sync_remote_address_space_triggers = optional(any, null)
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
      nat_gateway = optional(object({
        id = string
      }))
      service_endpoint_policies = optional(map(object({
        id = string
      })))
      ipam_pools = optional(list(object({
        pool_id         = string
        prefix_length   = optional(number)
        allocation_type = optional(string, "Static")
      })))
      sharing_scope                                 = optional(string)
      private_link_service_network_policies_enabled = optional(bool, true)
      default_outbound_access_enabled               = optional(bool, false)
      private_endpoint_network_policies             = optional(string, "Enabled")
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
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
      use_default_log_analytics                = optional(bool, true)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
  }))
  default     = {}
  description = "Map of spoke virtual networks with subnets and optional peerings. Refer to the main pattern module variable descriptions for complete details."
}

variable "private_dns_zones" {
  type = map(object({
    domain_name        = string
    resource_group_key = string
    virtual_network_links = optional(map(object({
      name                                   = string
      virtual_network_key                    = string
      registration_enabled                   = optional(bool, false)
      resolution_policy                      = optional(string, "Default")
      private_dns_zone_supports_private_link = optional(bool, false)
      tags                                   = optional(map(string), {})
    })), {})
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
    tags = optional(map(string), {})
  }))
  default     = {}
  description = "Map of Private DNS Zones to create. Refer to the main pattern module variable descriptions for complete details."
}

variable "byo_private_dns_zone_links" {
  type = map(object({
    name                                   = string
    private_dns_zone_id                    = string
    virtual_network_key                    = string
    registration_enabled                   = optional(bool, false)
    resolution_policy                      = optional(string, "Default")
    private_dns_zone_supports_private_link = optional(bool, false)
    tags                                   = optional(map(string), {})
  }))
  default     = {}
  description = "Map of BYO Private DNS Zone VNet links. Refer to the main pattern module variable descriptions for complete details."
}

variable "managed_identities" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    tags               = optional(map(string), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      scope                                  = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, null)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    federated_identity_credentials = optional(map(object({
      audience = list(string)
      issuer   = string
      name     = string
      subject  = string
    })), {})
  }))
  default     = {}
  description = "Map of user-assigned managed identities. Refer to the main pattern module variable descriptions for complete details."
}

variable "key_vaults" {
  type = map(object({
    name                            = string
    resource_group_key              = string
    location                        = optional(string)
    sku_name                        = optional(string, "premium")
    public_network_access_enabled   = optional(bool, false)
    purge_protection_enabled        = optional(bool, true)
    soft_delete_retention_days      = optional(number, null)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)
    network_acls = optional(object({
      bypass                     = optional(string, "None")
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = optional(string)
      managed_identity_key                   = optional(string)
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    private_endpoints = optional(map(object({
      name = optional(string, null)
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
      lock = optional(object({
        kind = string
        name = optional(string, null)
      }), null)
      network_configuration = object({
        subnet_resource_id = optional(string)
        vnet_key           = optional(string)
        subnet_key         = optional(string)
      })
      private_dns_zone = optional(object({
        resource_ids = optional(set(string))
        keys         = optional(set(string))
      }))
      private_dns_zone_group_name             = optional(string, "default")
      application_security_group_associations = optional(map(string), {})
      private_service_connection_name         = optional(string, null)
      network_interface_name                  = optional(string, null)
      location                                = optional(string, null)
      resource_group_name                     = optional(string, null)
      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
      })), {})
      tags = optional(map(string), null)
    })), {})
    contacts = optional(map(object({
      email = string
      name  = optional(string)
      phone = optional(string)
    })), {})
    keys = optional(map(object({
      name            = string
      key_type        = string
      key_opts        = optional(list(string), [])
      key_size        = optional(number)
      curve           = optional(string)
      not_before_date = optional(string)
      expiration_date = optional(string)
      tags            = optional(map(string))
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
      rotation_policy = optional(object({
        automatic = optional(object({
          time_after_creation = optional(string)
          time_before_expiry  = optional(string)
        }))
        expire_after         = optional(string)
        notify_before_expiry = optional(string)
      }))
    })), {})
    secrets = optional(map(object({
      name            = string
      content_type    = optional(string)
      tags            = optional(map(string))
      not_before_date = optional(string)
      expiration_date = optional(string)
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
    wait_for_rbac_before_key_operations = optional(object({
      create  = optional(string, "30s")
      destroy = optional(string, "0s")
    }))
    wait_for_rbac_before_secret_operations = optional(object({
      create  = optional(string, "30s")
      destroy = optional(string, "0s")
    }))
    wait_for_rbac_before_contact_operations = optional(object({
      create  = optional(string, "30s")
      destroy = optional(string, "0s")
    }))
    tags = optional(map(string), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
      use_default_log_analytics                = optional(bool, true)
    })), {})
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
      key         = optional(string)
      resource_id = optional(string)
    })
    internet_security_enabled = optional(bool, true)
    routing = optional(object({
      associated_route_table_id = string
      propagated_route_table = optional(object({
        route_table_ids = optional(list(string), [])
        labels          = optional(list(string), [])
      }))
      static_vnet_route = optional(object({
        name                = optional(string)
        address_prefixes    = optional(list(string), [])
        next_hop_ip_address = optional(string)
      }))
    }))
  }))
  default     = {}
  description = "Map of vWAN hub connections linking spoke VNets to a Virtual Hub. Refer to the main pattern module variable descriptions for complete details."
}

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
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
      use_default_log_analytics                = optional(bool, true)
    })), {})
  }))
  default     = {}
  description = "Map of Bastion host configurations. Empty map disables Bastion. Refer to the main pattern module variable descriptions for complete details."
}

variable "flowlog_configuration" {
  type = object({
    network_watcher_id   = optional(string)
    network_watcher_name = optional(string)
    resource_group_name  = optional(string)
    location             = optional(string)
    flow_logs = optional(map(object({
      enabled  = bool
      name     = string
      vnet_key = string
      retention_policy = object({
        days    = number
        enabled = bool
      })
      storage_account = object({
        resource_id = optional(string)
        key         = optional(string)
      })
      traffic_analytics = optional(object({
        enabled               = bool
        interval_in_minutes   = optional(number)
        workspace_id          = optional(string)
        workspace_region      = optional(string)
        workspace_resource_id = optional(string)
      }))
      version = optional(number)
    })), null)
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
    tags = optional(map(string), {})
  })
  default     = null
  description = "Network Watcher flow log configuration. Null disables flow logs. Refer to the main pattern module variable descriptions for complete details."
}
