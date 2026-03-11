module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"

  suffix = var.use_random_suffix ? [random_pet.suffix[0].id] : []
}

data "azurerm_client_config" "current" {}

resource "random_pet" "suffix" {
  count = var.use_random_suffix ? 1 : 0

  length    = 1
  separator = ""
}

# ──────────────────────────────────────────────────────────────
# Cross-variable validation (preconditions on terraform_data)
# ──────────────────────────────────────────────────────────────

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = var.log_analytics_workspace_id != null || var.log_analytics_workspace_configuration != null
      error_message = "log_analytics_workspace_configuration must be provided when log_analytics_workspace_id is null, so that a Log Analytics workspace can be auto-created."
    }

    precondition {
      condition = alltrue([
        for k, link in var.private_dns_zone_links :
        contains(keys(var.virtual_networks), link.virtual_network_key)
      ])
      error_message = "DNS zone link references a virtual_network_key that does not exist in virtual_networks."
    }

    precondition {
      condition = alltrue([
        for kv_key, kv in var.key_vaults : alltrue([
          for ra_key, ra in kv.role_assignments :
          ra.managed_identity_key == null || contains(keys(var.managed_identities), ra.managed_identity_key)
        ])
      ])
      error_message = "Key Vault role assignment references a managed_identity_key that does not exist in managed_identities."
    }

    precondition {
      condition = alltrue([
        for ra_key, ra in var.role_assignments :
        ra.managed_identity_key == null || contains(keys(var.managed_identities), ra.managed_identity_key)
      ])
      error_message = "Standalone role assignment references a managed_identity_key that does not exist in managed_identities."
    }
  }
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.2"

  for_each = var.resource_groups

  name             = each.value.name
  location         = coalesce(each.value.location, var.location)
  tags             = merge(var.tags, each.value.tags)
  lock             = each.value.lock != null ? each.value.lock : var.lock
  role_assignments = each.value.role_assignments
}

module "log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  count = var.log_analytics_workspace_id == null ? 1 : 0

  name                                      = coalesce(var.log_analytics_workspace_configuration.name, module.naming.log_analytics_workspace.name)
  location                                  = coalesce(var.log_analytics_workspace_configuration.location, var.location)
  resource_group_name                       = local.resource_group_names[var.log_analytics_workspace_configuration.resource_group_key]
  log_analytics_workspace_sku               = var.log_analytics_workspace_configuration.sku
  log_analytics_workspace_retention_in_days = var.log_analytics_workspace_configuration.retention_in_days
  tags                                      = merge(var.tags, var.log_analytics_workspace_configuration.tags)
  lock                                      = var.lock
  role_assignments                          = var.log_analytics_workspace_configuration.role_assignments
  private_endpoints                         = var.log_analytics_workspace_configuration.private_endpoints
}

module "network_security_group" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = local.resource_group_names[each.value.resource_group_key]
  location            = coalesce(each.value.location, var.location)
  security_rules      = each.value.security_rules
  diagnostic_settings = local.diagnostic_settings_default
  lock                = var.lock
  tags                = merge(var.tags, each.value.tags)
  role_assignments    = each.value.role_assignments
}

module "route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  for_each = var.route_tables

  name                          = each.value.name
  resource_group_name           = local.resource_group_names[each.value.resource_group_key]
  location                      = coalesce(each.value.location, var.location)
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = each.value.routes
  lock                          = var.lock
  tags                          = merge(var.tags, each.value.tags)
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  for_each = var.virtual_networks

  name          = each.value.name
  parent_id     = local.resource_group_resource_ids[each.value.resource_group_key]
  location      = coalesce(each.value.location, var.location)
  address_space = each.value.address_space

  dns_servers          = each.value.dns_servers != null ? { dns_servers = each.value.dns_servers } : null
  ddos_protection_plan = each.value.ddos_protection_plan
  encryption           = each.value.encryption

  subnets = {
    for sk, sv in each.value.subnets : sk => merge(sv, {
      network_security_group = sv.network_security_group_key != null ? {
        id = local.nsg_resource_ids[sv.network_security_group_key]
      } : null
      route_table = sv.route_table_key != null ? {
        id = local.rt_resource_ids[sv.route_table_key]
      } : null
    })
  }

  peerings            = each.value.peerings
  diagnostic_settings = local.diagnostic_settings_default
  lock                = var.lock
  tags                = merge(var.tags, each.value.tags)
  role_assignments    = each.value.role_assignments
}

module "private_dns_zone_link" {
  source  = "Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link"
  version = "0.5.0"

  for_each = var.private_dns_zone_links

  name                 = each.value.name
  parent_id            = each.value.private_dns_zone_id
  virtual_network_id   = module.virtual_network[each.value.virtual_network_key].resource_id
  registration_enabled = each.value.registration_enabled
  resolution_policy    = each.value.resolution_policy
  tags                 = merge(var.tags, each.value.tags)
}

module "managed_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.4.0"

  for_each = var.managed_identities

  name                = each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = local.resource_group_names[each.value.resource_group_key]
  lock                = var.lock
  tags                = merge(var.tags, each.value.tags)
  role_assignments    = each.value.role_assignments
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  for_each = var.key_vaults

  name                          = each.value.name
  location                      = coalesce(each.value.location, var.location)
  resource_group_name           = local.resource_group_names[each.value.resource_group_key]
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = each.value.sku_name
  public_network_access_enabled = each.value.public_network_access_enabled
  purge_protection_enabled      = each.value.purge_protection_enabled
  soft_delete_retention_days    = each.value.soft_delete_retention_days
  network_acls                  = each.value.network_acls
  diagnostic_settings           = local.diagnostic_settings_default
  lock                          = var.lock
  tags                          = merge(var.tags, each.value.tags)

  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name = ra.role_definition_id_or_name
      principal_id               = ra.managed_identity_key != null ? local.managed_identity_principal_ids[ra.managed_identity_key] : ra.principal_id
      description                = ra.description
      principal_type             = ra.principal_type
    }
  }

  private_endpoints = each.value.private_endpoints
}

module "role_assignment" {
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.3.0"

  count = length(var.role_assignments) > 0 ? 1 : 0

  role_assignments_azure_resource_manager = {
    for ra_key, ra in var.role_assignments : ra_key => {
      role_definition_name = ra.role_definition_id_or_name
      scope                = ra.scope
      principal_id         = ra.managed_identity_key != null ? local.managed_identity_principal_ids[ra.managed_identity_key] : ra.principal_id
      description          = ra.description
      principal_type       = ra.principal_type
    }
  }
}

module "vnet_conn" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection"
  version = "0.13.5"

  for_each = var.vhub_connectivity_definitions

  virtual_network_connections = {
    (each.key) = {
      name                      = each.key
      virtual_hub_id            = each.value.vhub_resource_id
      remote_virtual_network_id = local.vhub_vnet_resource_ids[each.key]
      internet_security_enabled = each.value.internet_security_enabled
    }
  }
}

module "bastion_host" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.9.0"

  count = var.bastion_configuration != null ? 1 : 0

  name                      = coalesce(var.bastion_configuration.name, module.naming.bastion_host.name)
  location                  = coalesce(var.bastion_configuration.location, var.location)
  parent_id                 = local.resource_group_resource_ids[var.bastion_configuration.resource_group_key]
  sku                       = var.bastion_configuration.sku
  zones                     = var.bastion_configuration.zones
  ip_configuration          = var.bastion_configuration.ip_configuration
  virtual_network_id        = var.bastion_configuration.virtual_network_id
  copy_paste_enabled        = var.bastion_configuration.copy_paste_enabled
  file_copy_enabled         = var.bastion_configuration.file_copy_enabled
  ip_connect_enabled        = var.bastion_configuration.ip_connect_enabled
  kerberos_enabled          = var.bastion_configuration.kerberos_enabled
  private_only_enabled      = var.bastion_configuration.private_only_enabled
  scale_units               = var.bastion_configuration.scale_units
  session_recording_enabled = var.bastion_configuration.session_recording_enabled
  shareable_link_enabled    = var.bastion_configuration.shareable_link_enabled
  tunneling_enabled         = var.bastion_configuration.tunneling_enabled
  diagnostic_settings       = local.diagnostic_settings_default
  lock                      = var.lock
  tags                      = merge(var.tags, var.bastion_configuration.tags)
  role_assignments          = var.bastion_configuration.role_assignments
}

# ──────────────────────────────────────────────────────────────
# Network Watcher – Flow Logs (C3 / FR-040)
# ──────────────────────────────────────────────────────────────

module "network_watcher" {
  source  = "Azure/avm-res-network-networkwatcher/azurerm"
  version = "0.3.2"

  count = var.flowlog_configuration != null ? 1 : 0

  network_watcher_id   = var.flowlog_configuration.network_watcher_id
  network_watcher_name = var.flowlog_configuration.network_watcher_name
  resource_group_name  = var.flowlog_configuration.resource_group_name
  location             = coalesce(var.flowlog_configuration.location, var.location)
  flow_logs            = var.flowlog_configuration.flow_logs
  lock                 = var.lock
  tags                 = merge(var.tags, var.flowlog_configuration.tags)
}
