variable "location" {
  type        = string
  description = <<-EOT
    The Azure region for all resources. Changing this forces recreation of all resources.

    All AVM module calls default their location to this value when not overridden per-resource.
  EOT
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Common tags applied to all resources that support tagging. Per-resource tags are merged on top
    of these.

    Note: vHub connections (azurerm_virtual_hub_connection) do not support tags; this variable is
    not passed to the vWAN connection submodule.
  EOT
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
  description = <<-EOT
    Map of resource groups to create. The map key is used as a reference key for other resources.

    Uses: Azure/avm-res-resources-resourcegroup/azurerm v0.2.2
    See:  https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm

    - name:             Resource group name.
    - location:         Azure region. Defaults to var.location if not specified.
    - tags:             Per-resource-group tags, merged with var.tags.
    - lock:             Per-resource-group lock. See AVM module variable: lock.
    - role_assignments: Per-resource-group RBAC assignments.
                        See AVM module variable: role_assignments.
  EOT
}

variable "byo_log_analytics_workspace" {
  type = object({
    resource_id = string
    location    = string
  })
  default     = null
  description = <<-EOT
    Bring-your-own Log Analytics workspace. Provide the resource ID and location of an
    existing workspace. If null, the pattern auto-creates one using
    log_analytics_workspace_configuration.
  EOT
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
  description = <<-EOT
    Configuration for the auto-created Log Analytics workspace. Used only when
    byo_log_analytics_workspace is null.

    Uses: Azure/avm-res-operationalinsights-workspace/azurerm v0.5.1
    See:  https://registry.terraform.io/modules/Azure/avm-res-operationalinsights-workspace/azurerm

    - name:               Workspace name (required).
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - sku:                Pricing tier. Default: "PerGB2018".
    - retention_in_days:  Data retention. Default: 30.
    - tags:               Per-workspace tags, merged with var.tags.
    - lock:               Resource lock for the workspace. See AVM module variable: lock.
    - role_assignments:   Per-workspace RBAC assignments.
                          See AVM module variable: role_assignments.
    - private_endpoints:  Private endpoint configurations for the workspace.
                          See AVM module variable: private_endpoints.
  EOT
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
  description = <<-EOT
    Map of Network Security Groups. The map key is used as a reference key for subnet associations.

    Uses: Azure/avm-res-network-networksecuritygroup/azurerm v0.5.1
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-networksecuritygroup/azurerm

    - name:               NSG name.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - security_rules:     Map of user-defined security rules. An empty map means only Azure
                          built-in default rules apply. No rules are auto-injected.
    - tags:               Per-NSG tags, merged with var.tags.
    - lock:               Resource lock for the NSG. See AVM module variable: lock.
    - role_assignments:   Per-NSG RBAC assignments.
                          See AVM module variable: role_assignments.
    - diagnostic_settings: Per-NSG diagnostic settings. Each entry can send logs/metrics to a
                          Log Analytics workspace, storage account, Event Hub, or partner solution.
                          Set use_default_log_analytics = true (default) to auto-fill
                          workspace_resource_id with the pattern's LAW (BYO or auto-created).
                          Set to false to use workspace_resource_id as-is (null = not sent to LAW).
  EOT
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
  description = <<-EOT
    Map of route tables. Each can contain multiple routes. Associate to subnets via the subnet's
    route_table_key.

    Uses: Azure/avm-res-network-routetable/azurerm v0.5.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-routetable/azurerm

    - name:                          Route table name.
    - resource_group_key:            Key in resource_groups map for placement.
    - location:                      Azure region. Defaults to var.location.
    - bgp_route_propagation_enabled: Enable BGP route propagation. Default: true.
    - routes:                        Map of routes with address_prefix and next_hop_type.
    - lock:                          Resource lock for the route table. See AVM module variable: lock.
    - tags:                          Per-route-table tags, merged with var.tags.
  EOT
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
  description = <<-EOT
    Map of spoke virtual networks. Each entry creates a VNet with optional subnets and optional hub
    peerings via the AVM VNet module's peerings interface.

    Uses: Azure/avm-res-network-virtualnetwork/azurerm v0.17.1
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm

    - name:               VNet name.
    - address_space:      Set of CIDR ranges for the virtual network.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - dns_servers:        Custom DNS servers. Null uses Azure-provided DNS.
    - ddos_protection_plan: DDoS Protection Plan configuration.
    - encryption:         VNet encryption settings.
    - tags:               Per-VNet tags, merged with var.tags.
    - lock:               Resource lock for the VNet. See AVM module variable: lock.
    - peerings:           Map of VNet peerings. Empty map = no peering (implicit toggle).
    - subnets:            Map of subnets. Each can reference NSG and route table by key.
                          Subnets support their own role_assignments.
    - role_assignments:   VNet-level RBAC assignments.
                          See AVM module variable: role_assignments.
    - diagnostic_settings: Per-VNet diagnostic settings. Each entry can send logs/metrics to a
                          Log Analytics workspace, storage account, Event Hub, or partner solution.
                          Set use_default_log_analytics = true (default) to auto-fill
                          workspace_resource_id with the pattern's LAW (BYO or auto-created).
                          Set to false to use workspace_resource_id as-is (null = not sent to LAW).
  EOT

  validation {
    condition = alltrue([
      for vk, vnet in var.virtual_networks : alltrue([
        for sk, subnet in vnet.subnets : (subnet.address_prefix != null) != (subnet.address_prefixes != null)
      ])
    ])
    error_message = "Each subnet must define exactly one of address_prefix or address_prefixes, not both."
  }
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
  description = <<-EOT
    Map of Private DNS Zones to create and optionally link to VNets created by this pattern.

    Uses: Azure/avm-res-network-privatednszone/azurerm v0.5.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-privatednszone/azurerm

    - domain_name:          Domain name for the Private DNS Zone (e.g. "privatelink.blob.core.windows.net").
    - resource_group_key:   Key in resource_groups map for placement.
    - virtual_network_links: Map of VNet links. Each references a VNet by key from virtual_networks map.
      - name:                 Link name.
      - virtual_network_key:  Key in virtual_networks map identifying the VNet to link.
      - registration_enabled: Enable auto-registration of VM DNS records. Default: false.
      - resolution_policy:    Resolution policy. Default: "Default".
      - tags:                 Per-link tags, merged with var.tags.
    - tags:                 Per-zone tags, merged with var.tags.
    - lock:                 Resource lock for the DNS zone. See AVM module variable: lock.

    For linking to existing (BYO) Private DNS Zones not managed by this pattern, use
    byo_private_dns_zone_links instead.
  EOT
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
  description = <<-EOT
    Map of VNet links to existing (BYO) Private DNS Zones. Each links an existing DNS zone (by
    resource ID) to a VNet created by this pattern (by map key).

    For creating Private DNS Zones as part of this pattern, use private_dns_zones instead.

    Uses: Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link v0.5.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-privatednszone/azurerm

    - name:                 Link name.
    - private_dns_zone_id:  Resource ID of the existing Private DNS Zone to link.
    - virtual_network_key:  Key in virtual_networks map identifying the VNet.
    - registration_enabled: Enable auto-registration. Default: false.
    - resolution_policy:    Resolution policy. Default: "Default".
    - tags:                 Per-link tags, merged with var.tags.
  EOT
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
  description = <<-EOT
    Map of user-assigned managed identities to create.

    Uses: Azure/avm-res-managedidentity-userassignedidentity/azurerm v0.4.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-managedidentity-userassignedidentity/azurerm

    - name:               Identity name.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - tags:               Per-identity tags, merged with var.tags.
    - lock:               Resource lock for the identity. See AVM module variable: lock.
    - role_assignments:   Per-identity RBAC assignments.
                          See AVM module variable: role_assignments.
  EOT
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
  description = <<-EOT
    Map of Key Vaults.

    Uses: Azure/avm-res-keyvault-vault/azurerm v0.10.2
    See:  https://registry.terraform.io/modules/Azure/avm-res-keyvault-vault/azurerm

    - name:                          Key Vault name.
    - resource_group_key:            Key in resource_groups map for placement.
    - location:                      Azure region. Defaults to var.location.
    - sku_name:                      SKU tier. Default: "premium".
    - public_network_access_enabled: Default: false (secure-by-default, overrides AVM default).
    - purge_protection_enabled:      Default: true.
    - soft_delete_retention_days:    Soft-delete retention. Default: null (AVM default).
    - network_acls:                  Network ACL configuration. Default: bypass=None, action=Deny.
    - role_assignments:              Per-Key-Vault RBAC assignments. Supports principal_id (direct)
                                     or managed_identity_key (from managed_identities map).
                                     Exactly one must be set per assignment.
    - private_endpoints:             Private endpoint configurations.
                                     See AVM module variable: private_endpoints.
    - tags:                          Per-Key-Vault tags, merged with var.tags.
    - lock:                          Resource lock for the Key Vault. See AVM module variable: lock.
    - diagnostic_settings:           Per-Key-Vault diagnostic settings. Each entry can send
                                     logs/metrics to a Log Analytics workspace, storage account,
                                     Event Hub, or partner solution. Set use_default_log_analytics
                                     = true (default) to auto-fill workspace_resource_id with the
                                     pattern's LAW (BYO or auto-created). Set to false to use
                                     workspace_resource_id as-is (null = not sent to LAW).
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

    Uses: Azure/avm-res-authorization-roleassignment/azurerm v0.3.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-authorization-roleassignment/azurerm

    - role_definition_id_or_name: Role name or ID.
    - scope:                      Azure resource ID scope for the assignment.
    - principal_id:               Direct principal ID. Mutually exclusive with managed_identity_key.
    - managed_identity_key:       Key in managed_identities map. Mutually exclusive with principal_id.
    - description:                Optional description for the assignment.
    - principal_type:             Optional principal type hint.
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
  description = <<-EOT
    Map of vWAN hub connections. Each entry links a spoke VNet to a vWAN hub.

    Uses: Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection v0.13.5
    See:  https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm

    - vhub_resource_id:          Resource ID of the target Virtual Hub.
    - virtual_network:           Reference the spoke VNet by key (from virtual_networks map) or by
                                 resource ID. Exactly one of key or resource_id must be set.
    - internet_security_enabled: Route internet traffic through hub firewall. Default: true
                                 (secure-by-default).
    - routing:                   Optional routing configuration for the connection.
      - associated_route_table_id: Resource ID of the Virtual Hub Route Table to associate.
      - propagated_route_table:    Optional propagation config.
        - route_table_ids:         List of Virtual Hub Route Table resource IDs to propagate to.
        - labels:                  List of labels to propagate to.
      - static_vnet_route:         Optional static VNet route.
        - name:                    Name for the static route.
        - address_prefixes:        List of address prefixes.
        - next_hop_ip_address:     Next hop IP address.

    Empty map = no vWAN connections (implicit toggle).
  EOT

  validation {
    condition     = alltrue([for k, v in var.vhub_connectivity_definitions : (v.virtual_network.key != null) != (v.virtual_network.resource_id != null)])
    error_message = "Each vhub_connectivity_definition must set exactly one of virtual_network.key or virtual_network.resource_id."
  }
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
  description = <<-EOT
    Map of Azure Bastion Host configurations, keyed by a user-chosen identifier.
    Empty map = no Bastion hosts deployed.

    Uses: Azure/avm-res-network-bastionhost/azurerm v0.9.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-bastionhost/azurerm

    - name:                    Bastion name (required).
    - resource_group_key:      Key in resource_groups map for placement.
    - location:                Azure region. Defaults to var.location.
    - sku:                     SKU tier. Default: "Standard".
    - zones:                   Availability zones. Default: ["1","2","3"] (zone-redundant).
    - ip_configuration:        Required for non-Developer SKUs. Provide subnet_resource_id
                               directly, or use vnet_key + subnet_key to resolve from
                               virtual_networks map.
    - virtual_network:         For Developer SKU only. Omit ip_configuration. Provide
                               resource_id directly or key to resolve from virtual_networks map.
    - role_assignments:        Per-Bastion RBAC assignments.
                               See AVM module variable: role_assignments.
    - diagnostic_settings:     Per-Bastion diagnostic settings. Each entry can send logs/metrics
                               to a Log Analytics workspace, storage account, Event Hub, or
                               partner solution. Set use_default_log_analytics = true (default)
                               to auto-fill workspace_resource_id with the pattern's LAW (BYO or
                               auto-created). Set to false to use workspace_resource_id as-is
                               (null = not sent to LAW).
    - tags:                    Per-Bastion tags, merged with var.tags.
    - lock:                    Resource lock for the Bastion host. See AVM module variable: lock.
  EOT
}

# ──────────────────────────────────────────────────────────────
# Storage Accounts
# ──────────────────────────────────────────────────────────────

variable "storage_accounts" {
  type = map(object({
    name                              = string
    resource_group_key                = string
    location                          = optional(string)
    account_tier                      = optional(string, "Standard")
    account_replication_type          = optional(string, "ZRS")
    account_kind                      = optional(string, "StorageV2")
    access_tier                       = optional(string, "Hot")
    shared_access_key_enabled         = optional(bool, false)
    public_network_access_enabled     = optional(bool, false)
    https_traffic_only_enabled        = optional(bool, true)
    min_tls_version                   = optional(string, "TLS1_2")
    allow_nested_items_to_be_public   = optional(bool, false)
    allowed_copy_scope                = optional(string)
    cross_tenant_replication_enabled  = optional(bool, false)
    default_to_oauth_authentication   = optional(bool)
    infrastructure_encryption_enabled = optional(bool, false)
    nfsv3_enabled                     = optional(bool, false)
    sftp_enabled                      = optional(bool, false)
    is_hns_enabled                    = optional(bool)
    large_file_share_enabled          = optional(bool)
    customer_managed_key = optional(object({
      key_vault_resource_id = string
      key_name              = string
      key_version           = optional(string)
      user_assigned_identity = optional(object({
        resource_id = string
      }))
    }))
    sas_policy = optional(object({
      expiration_action = optional(string, "Log")
      expiration_period = string
    }))
    immutability_policy = optional(object({
      allow_protected_append_writes = bool
      period_since_creation_in_days = number
      state                         = string
    }))
    blob_properties = optional(object({
      change_feed_enabled           = optional(bool, false)
      change_feed_retention_in_days = optional(number)
      default_service_version       = optional(string)
      last_access_time_enabled      = optional(bool, false)
      versioning_enabled            = optional(bool, false)
      container_delete_retention_policy = optional(object({
        enabled = optional(bool, true)
        days    = optional(number, 7)
      }))
      delete_retention_policy = optional(object({
        enabled                  = optional(bool, true)
        days                     = optional(number, 7)
        permanent_delete_enabled = optional(bool, false)
      }))
      restore_policy = optional(object({
        days = number
      }))
      cors_rule = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), [])
    }))
    share_properties = optional(object({
      retention_policy = optional(object({
        days = optional(number, 7)
      }))
      smb = optional(object({
        authentication_types            = optional(set(string))
        channel_encryption_type         = optional(set(string))
        kerberos_ticket_encryption_type = optional(set(string))
        multichannel_enabled            = optional(bool, false)
        versions                        = optional(set(string))
      }))
      cors_rule = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), [])
    }))
    queue_properties = optional(map(object({
      cors_rule = optional(map(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), {})
      logging = optional(object({
        delete                = bool
        read                  = bool
        version               = string
        write                 = bool
        retention_policy_days = optional(number)
      }))
      hour_metrics = optional(object({
        include_apis          = optional(bool)
        retention_policy_days = optional(number)
        version               = string
      }))
      minute_metrics = optional(object({
        include_apis          = optional(bool)
        retention_policy_days = optional(number)
        version               = string
      }))
    })), {})
    azure_files_authentication = optional(object({
      directory_type                 = optional(string)
      default_share_level_permission = optional(string)
      active_directory = optional(object({
        domain_guid         = string
        domain_name         = string
        domain_sid          = optional(string)
        forest_name         = optional(string)
        netbios_domain_name = optional(string)
        storage_sid         = optional(string)
      }))
    }))
    routing = optional(object({
      choice                      = optional(string)
      publish_internet_endpoints  = optional(bool, false)
      publish_microsoft_endpoints = optional(bool, false)
    }))
    custom_domain = optional(object({
      name          = string
      use_subdomain = optional(bool)
    }))
    queues = optional(map(object({
      metadata = optional(map(string))
      name     = string
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
    tables = optional(map(object({
      name = string
      signed_identifiers = optional(list(object({
        id = string
        access_policy = optional(object({
          expiry_time = string
          permission  = string
          start_time  = string
        }))
      })))
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
    shares = optional(map(object({
      access_tier      = optional(string)
      enabled_protocol = optional(string)
      metadata         = optional(map(string))
      name             = string
      quota            = number
      root_squash      = optional(string)
      signed_identifiers = optional(list(object({
        id = string
        access_policy = optional(object({
          expiry_time = string
          permission  = string
          start_time  = string
        }))
      })))
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
    queue_encryption_key_type = optional(string)
    table_encryption_key_type = optional(string)
    storage_management_policy_rule = optional(map(object({
      enabled = bool
      name    = string
      actions = object({
        base_blob = optional(object({
          auto_tier_to_hot_from_cool_enabled                             = optional(bool)
          delete_after_days_since_creation_greater_than                  = optional(number)
          delete_after_days_since_last_access_time_greater_than          = optional(number)
          delete_after_days_since_modification_greater_than              = optional(number)
          tier_to_archive_after_days_since_creation_greater_than         = optional(number)
          tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          tier_to_archive_after_days_since_modification_greater_than     = optional(number)
          tier_to_cold_after_days_since_creation_greater_than            = optional(number)
          tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
          tier_to_cold_after_days_since_modification_greater_than        = optional(number)
          tier_to_cool_after_days_since_creation_greater_than            = optional(number)
          tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
          tier_to_cool_after_days_since_modification_greater_than        = optional(number)
        }))
        snapshot = optional(object({
          change_tier_to_archive_after_days_since_creation               = optional(number)
          change_tier_to_cool_after_days_since_creation                  = optional(number)
          delete_after_days_since_creation_greater_than                  = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        }))
        version = optional(object({
          change_tier_to_archive_after_days_since_creation               = optional(number)
          change_tier_to_cool_after_days_since_creation                  = optional(number)
          delete_after_days_since_creation                               = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        }))
      })
      filters = object({
        blob_types   = set(string)
        prefix_match = optional(set(string))
        match_blob_index_tag = optional(set(object({
          name      = string
          operation = optional(string)
          value     = string
        })))
      })
    })), {})
    network_rules = optional(object({
      bypass                     = optional(set(string), ["AzureServices"])
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(set(string), [])
      virtual_network_subnet_ids = optional(set(string), [])
      private_link_access = optional(list(object({
        endpoint_resource_id = string
        endpoint_tenant_id   = optional(string)
      })))
    }), {})
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    }), {})
    containers = optional(map(object({
      name                           = string
      public_access                  = optional(string, "None")
      metadata                       = optional(map(string))
      default_encryption_scope       = optional(string)
      deny_encryption_scope_override = optional(bool)
      enable_nfs_v3_all_squash       = optional(bool)
      enable_nfs_v3_root_squash      = optional(bool)
      immutable_storage_with_versioning = optional(object({
        enabled = bool
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
      subresource_name = string
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
    }))
    tags = optional(map(string), {})
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
    diagnostic_settings_blob = optional(map(object({
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
    diagnostic_settings_file = optional(map(object({
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
    diagnostic_settings_queue = optional(map(object({
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
    diagnostic_settings_table = optional(map(object({
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
  description = <<-EOT
    Map of storage accounts to create. The map key is used as a reference key
    (e.g. by flowlog_configuration.flow_logs.storage_account_key).

    Uses: Azure/avm-res-storage-storageaccount/azurerm v0.6.7
    See:  https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm

    - name:                          Storage account name (must be globally unique).
    - resource_group_key:            Key in resource_groups map for placement.
    - location:                      Azure region. Defaults to var.location.
    - account_tier:                  Tier. Default: "Standard".
    - account_replication_type:      Replication. Default: "ZRS".
    - account_kind:                  Kind. Default: "StorageV2".
    - access_tier:                   Access tier. Default: "Hot".
    - shared_access_key_enabled:     Default: false (Entra-only auth).
    - public_network_access_enabled: Default: false (secure-by-default).
    - network_rules:                 Network ACL configuration. Default: bypass AzureServices, deny.
    - managed_identities:            System/user-assigned identity configuration.
    - containers:                    Map of blob containers.
    - private_endpoints:             Private endpoint configurations.
    - role_assignments:              Per-storage RBAC assignments.
    - lock:                          Resource lock for the storage account. See AVM module variable: lock.
    - tags:                          Per-storage tags, merged with var.tags.
    - diagnostic_settings:           Per-storage-account diagnostic settings. Each entry can send
                                     logs/metrics to a Log Analytics workspace, storage account,
                                     Event Hub, or partner solution. Set use_default_log_analytics
                                     = true (default) to auto-fill workspace_resource_id with the
                                     pattern's LAW (BYO or auto-created). Set to false to use
                                     workspace_resource_id as-is (null = not sent to LAW).
    - diagnostic_settings_blob:      Per-blob-service diagnostic settings. Same structure and
                                     use_default_log_analytics behaviour as diagnostic_settings.
                                     See AVM module variable: diagnostic_settings_blob.
    - diagnostic_settings_file:      Per-file-service diagnostic settings. Same structure and
                                     use_default_log_analytics behaviour as diagnostic_settings.
                                     See AVM module variable: diagnostic_settings_file.
    - diagnostic_settings_queue:     Per-queue-service diagnostic settings. Same structure and
                                     use_default_log_analytics behaviour as diagnostic_settings.
                                     See AVM module variable: diagnostic_settings_queue.
    - diagnostic_settings_table:     Per-table-service diagnostic settings. Same structure and
                                     use_default_log_analytics behaviour as diagnostic_settings.
                                     See AVM module variable: diagnostic_settings_table.
  EOT
}

# ──────────────────────────────────────────────────────────────
# Network Watcher / Flow Logs
# ──────────────────────────────────────────────────────────────

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
  description = <<-EOT
    Network Watcher and VNet flow log configuration. When null (default), no Network Watcher or
    flow logs are configured (implicit toggle).

    Uses: Azure/avm-res-network-networkwatcher/azurerm v0.3.2
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-networkwatcher/azurerm

    - network_watcher_id:   Resource ID of the existing Network Watcher. Defaults to the Azure
                            auto-created NetworkWatcher_<location> in NetworkWatcherRG.
    - network_watcher_name: Name of the existing Network Watcher. Defaults to
                            NetworkWatcher_<location>.
    - resource_group_name:  Resource group containing the Network Watcher. Defaults to
                            NetworkWatcherRG.
    - location:             Azure region. Defaults to var.location.
    - flow_logs:            Map of VNet flow log configurations. Each requires vnet_key (key in
                            virtual_networks map), retention_policy, and storage_account. Provide
                            either storage_account.resource_id (direct) or storage_account.key
                            (reference to storage_accounts map). Optional traffic_analytics —
                            workspace_id, workspace_region, and workspace_resource_id default to
                            values from the pattern's Log Analytics workspace (internal or BYO).
    - tags:                 Per-resource tags, merged with var.tags.
    - lock:                 Resource lock for the Network Watcher. See AVM module variable: lock.
  EOT
}
