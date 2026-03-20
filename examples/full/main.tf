# ---------------------------------------------------------------------------
# Full Example – All Features Enabled
# ---------------------------------------------------------------------------
# Creates an inline hub VNet as a peering target and deploys the pattern
# module exercising every configurable feature. Private DNS Zones are
# created by the pattern module's private_dns_zones variable (no inline
# azurerm_private_dns_zone resources needed). The flow-log storage account
# is created by the pattern module's storage_accounts variable.
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Inline dependencies — hub VNet as peering target
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-networking-full"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-full"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Construct computed references for spoke resources created by pattern module
# ---------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # Merge computed IDs into variable values
  # ---------------------------------------------------------------------------

  # Add peering with computed hub VNet ID
  virtual_networks = {
    for k, v in var.virtual_networks : k => merge(v, {
      peerings = merge(v.peerings, {
        to_hub = {
          name                               = "spoke-to-hub"
          remote_virtual_network_resource_id = azurerm_virtual_network.hub.id
          allow_forwarded_traffic            = true
          allow_gateway_transit              = false
          use_remote_gateways                = false
        }
      })
    })
  }

  # BYO DNS zone links with computed private DNS zone ID
  byo_private_dns_zone_links = merge(var.byo_private_dns_zone_links, {
    byo_dns_kv = merge(var.byo_private_dns_zone_links.byo_dns_kv, {
      private_dns_zone_id = azurerm_private_dns_zone.kv.id
    })
  })

  # Standalone role assignments with computed spoke RG scope
  role_assignments = {
    for k, v in var.role_assignments : k => merge(v, k == "ra_spoke_rg_reader" ? {
      scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_groups["rg_networking"].name}"
    } : {})
  }
}

# ---------------------------------------------------------------------------
# Pattern module — spoke shared services (all features)
# ---------------------------------------------------------------------------

module "pattern" {
  source = "../.."

  location                              = var.location
  tags                                  = var.tags
  enable_telemetry                      = var.enable_telemetry
  resource_groups                       = var.resource_groups
  byo_log_analytics_workspace           = var.byo_log_analytics_workspace
  log_analytics_workspace_configuration = var.log_analytics_workspace_configuration
  network_security_groups               = var.network_security_groups
  route_tables                          = var.route_tables
  virtual_networks                      = local.virtual_networks
  private_dns_zones                     = var.private_dns_zones
  byo_private_dns_zone_links            = local.byo_private_dns_zone_links
  managed_identities                    = var.managed_identities
  key_vaults                            = var.key_vaults
  role_assignments                      = local.role_assignments
  vhub_connectivity_definitions         = var.vhub_connectivity_definitions
  bastion_hosts                         = var.bastion_hosts
  storage_accounts                      = var.storage_accounts
  flowlog_configuration                 = var.flowlog_configuration
  recovery_services_vaults              = var.recovery_services_vaults
  backup_vaults                         = var.backup_vaults

  depends_on = [azurerm_virtual_network.hub, azurerm_private_dns_zone.kv]
}
