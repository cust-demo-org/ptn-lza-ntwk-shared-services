locals {
  # Resource group name lookup: resolve resource_group_key → resource group name
  resource_group_names = { for key, mod in module.resource_group : key => mod.name }

  # Resource group ID lookup: resolve resource_group_key → resource group resource ID
  resource_group_resource_ids = { for key, mod in module.resource_group : key => mod.resource_id }

  # Log Analytics workspace ID: use external ID if provided, otherwise use auto-created workspace
  log_analytics_workspace_id = coalesce(
    var.log_analytics_workspace_id,
    try(module.log_analytics_workspace[0].resource_id, null)
  )

  # Default diagnostic settings passed to all AVM modules (except the auto-created LAW itself)
  diagnostic_settings_default = local.log_analytics_workspace_id != null ? {
    to_law = {
      name                  = "diag-to-law"
      workspace_resource_id = local.log_analytics_workspace_id
    }
  } : {}

  # NSG resource ID lookup: resolve NSG key → resource ID for subnet associations
  nsg_resource_ids = { for key, mod in module.network_security_group : key => mod.resource_id }

  # Route table resource ID lookup: resolve RT key → resource ID for subnet associations
  rt_resource_ids = { for key, mod in module.route_table : key => mod.resource_id }

  # Managed identity principal ID lookup: resolve MI key → principal ID for role assignments
  managed_identity_principal_ids = { for key, mod in module.managed_identity : key => mod.principal_id }

  # vHub connection VNet ID resolution: resolve virtual_network.key → resource ID, or pass through virtual_network.id
  vhub_vnet_resource_ids = {
    for k, v in var.vhub_connectivity_definitions : k => (
      v.virtual_network.key != null
      ? module.virtual_network[v.virtual_network.key].resource_id
      : v.virtual_network.id
    )
  }
}
