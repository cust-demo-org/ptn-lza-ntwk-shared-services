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

variable "use_random_suffix" {
  type        = bool
  default     = false
  description = <<-EOT
    When true, globally-unique resources (e.g., Key Vault) receive a random suffix via the
    Azure/naming/azurerm module. Default: false (CAF names only).
  EOT
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<-EOT
    Resource lock applied to AVM root-module resources that expose the lock interface (resource
    group, VNet, NSG, route table, Key Vault, Bastion, Log Analytics workspace, managed identity).

    Does not apply to AVM submodule resources (DNS zone VNet links, vHub connections) as those
    submodules do not implement the lock interface. Per-resource-group lock overrides are available
    via the resource_groups variable's lock field.

    Set to null to disable. Possible kind values: 'CanNotDelete', 'ReadOnly'.
  EOT

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
    - lock:             Per-resource-group lock override. When set, overrides var.lock for this RG.
                        See AVM module variable: lock.
    - role_assignments: Per-resource-group RBAC assignments.
                        See AVM module variable: role_assignments.
  EOT
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = <<-EOT
    Resource ID of an existing Log Analytics workspace. If null, the pattern auto-creates one
    using log_analytics_workspace_configuration.
  EOT
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
  description = <<-EOT
    Configuration for the auto-created Log Analytics workspace. Used only when
    log_analytics_workspace_id is null.

    Uses: Azure/avm-res-operationalinsights-workspace/azurerm v0.5.1
    See:  https://registry.terraform.io/modules/Azure/avm-res-operationalinsights-workspace/azurerm

    - name:               Workspace name. Defaults to naming module output if null.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - sku:                Pricing tier. Default: "PerGB2018".
    - retention_in_days:  Data retention. Default: 30.
    - tags:               Per-workspace tags, merged with var.tags.
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
    Map of Network Security Groups. The map key is used as a reference key for subnet associations.

    Uses: Azure/avm-res-network-networksecuritygroup/azurerm v0.5.1
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-networksecuritygroup/azurerm

    - name:               NSG name.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - security_rules:     Map of user-defined security rules. An empty map means only Azure
                          built-in default rules apply. No rules are auto-injected.
    - tags:               Per-NSG tags, merged with var.tags.
    - role_assignments:   Per-NSG RBAC assignments.
                          See AVM module variable: role_assignments.
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
    - peerings:           Map of VNet peerings. Empty map = no peering (implicit toggle).
    - subnets:            Map of subnets. Each can reference NSG and route table by key.
                          Subnets support their own role_assignments.
    - role_assignments:   VNet-level RBAC assignments.
                          See AVM module variable: role_assignments.
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
  description = <<-EOT
    Map of Private DNS Zone VNet links. Each links an existing DNS zone (by resource ID) to a spoke
    VNet (by map key).

    Uses: Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link v0.5.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-privatednszone/azurerm

    - name:                 Link name.
    - private_dns_zone_id:  Resource ID of the Private DNS Zone to link.
    - virtual_network_key:  Key in virtual_networks map identifying the spoke VNet.
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
  description = <<-EOT
    Map of user-assigned managed identities to create.

    Uses: Azure/avm-res-managedidentity-userassignedidentity/azurerm v0.4.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-managedidentity-userassignedidentity/azurerm

    - name:               Identity name.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - tags:               Per-identity tags, merged with var.tags.
    - role_assignments:   Per-identity RBAC assignments.
                          See AVM module variable: role_assignments.
  EOT
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
      key = optional(string)
      id  = optional(string)
    })
    internet_security_enabled = optional(bool, true)
  }))
  default     = {}
  description = <<-EOT
    Map of vWAN hub connections. Each entry links a spoke VNet to a vWAN hub.

    Uses: Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection v0.13.5
    See:  https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm

    - vhub_resource_id:        Resource ID of the target Virtual Hub.
    - virtual_network:         Reference the spoke VNet by key (from virtual_networks map) or by
                               resource ID. Exactly one of key or id must be set.
    - internet_security_enabled: Route internet traffic through hub firewall. Default: true
                               (secure-by-default).

    Empty map = no vWAN connections (implicit toggle).
  EOT

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
  description = <<-EOT
    Bastion host configuration. When non-null, deploys an Azure Bastion Host
    (implicit toggle — null = no Bastion).

    Uses: Azure/avm-res-network-bastionhost/azurerm v0.9.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-bastionhost/azurerm

    - name:                    Bastion name. Defaults to naming module output.
    - resource_group_key:      Key in resource_groups map for placement.
    - location:                Azure region. Defaults to var.location.
    - sku:                     SKU tier. Default: "Standard".
    - zones:                   Availability zones. Default: ["1","2","3"] (zone-redundant).
    - ip_configuration:        Required for non-Developer SKUs. subnet_id must point to an
                               AzureBastionSubnet (minimum /26).
    - virtual_network_id:      For Developer SKU only. Omit ip_configuration.
    - role_assignments:        Per-Bastion RBAC assignments.
                               See AVM module variable: role_assignments.
    - tags:                    Per-Bastion tags, merged with var.tags.
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
    Network Watcher and VNet flow log configuration. When null (default), no Network Watcher or
    flow logs are configured (implicit toggle).

    Uses: Azure/avm-res-network-networkwatcher/azurerm v0.3.2
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-networkwatcher/azurerm

    - network_watcher_id:   Resource ID of the existing Network Watcher.
    - network_watcher_name: Name of the existing Network Watcher.
    - resource_group_name:  Resource group containing the Network Watcher.
    - location:             Azure region. Defaults to var.location.
    - flow_logs:            Map of VNet flow log configurations. Each requires target_resource_id,
                            storage_account_id, and retention_policy. Optional traffic_analytics.
    - tags:                 Per-resource tags, merged with var.tags.
  EOT
}
