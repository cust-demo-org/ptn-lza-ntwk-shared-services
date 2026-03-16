# ---------------------------------------------------------------------------
# VNet Hub Peering Example
# ---------------------------------------------------------------------------
# Creates an inline hub VNet as a peering target, then deploys the spoke
# pattern module with VNet-to-VNet peering to the hub.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Inline dependencies — hub VNet as peering target
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-networking-vnethub"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-vnethub"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Merge computed hub VNet ID into spoke peering configuration
# ---------------------------------------------------------------------------

locals {
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
}

# ---------------------------------------------------------------------------
# Pattern module — spoke shared services
# ---------------------------------------------------------------------------

module "pattern" {
  source = "../.."

  location                              = var.location
  tags                                  = var.tags
  lock                                  = var.lock
  resource_groups                       = var.resource_groups
  byo_log_analytics_workspace           = var.byo_log_analytics_workspace
  log_analytics_workspace_configuration = var.log_analytics_workspace_configuration
  network_security_groups               = var.network_security_groups
  route_tables                          = var.route_tables
  virtual_networks                      = local.virtual_networks
  private_dns_zones                     = var.private_dns_zones
  byo_private_dns_zone_links            = var.byo_private_dns_zone_links
  managed_identities                    = var.managed_identities
  key_vaults                            = var.key_vaults
  role_assignments                      = var.role_assignments
  vhub_connectivity_definitions         = var.vhub_connectivity_definitions
  bastion_hosts                         = var.bastion_hosts
  flowlog_configuration                 = var.flowlog_configuration

  depends_on = [azurerm_virtual_network.hub]
}
