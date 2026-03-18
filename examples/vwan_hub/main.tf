# ---------------------------------------------------------------------------
# vWAN Hub Connectivity Example
# ---------------------------------------------------------------------------
# Creates an inline Virtual WAN and Virtual Hub, then deploys the spoke
# pattern module with vHub connectivity instead of traditional VNet peering.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Inline dependencies — Virtual WAN + Virtual Hub
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "connectivity" {
  name     = "rg-connectivity-vwanhub"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_wan" "main" {
  name                = "vwan-shared-vwanhub"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  tags                = var.tags
}

resource "azurerm_virtual_hub" "main" {
  name                = "vhub-vwanhub-${var.location}"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  virtual_wan_id      = azurerm_virtual_wan.main.id
  address_prefix      = "10.0.0.0/23"
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Construct vHub connectivity definitions with computed vHub ID
# ---------------------------------------------------------------------------

locals {
  vhub_connectivity_definitions = {
    conn_spoke = {
      vhub_resource_id = azurerm_virtual_hub.main.id
      virtual_network = {
        key = "vnet_spoke"
      }
      internet_security_enabled = true
    }
  }
}

# ---------------------------------------------------------------------------
# Pattern module — spoke shared services
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
  virtual_networks                      = var.virtual_networks
  private_dns_zones                     = var.private_dns_zones
  byo_private_dns_zone_links            = var.byo_private_dns_zone_links
  managed_identities                    = var.managed_identities
  key_vaults                            = var.key_vaults
  role_assignments                      = var.role_assignments
  vhub_connectivity_definitions         = local.vhub_connectivity_definitions
  bastion_hosts                         = var.bastion_hosts
  flowlog_configuration                 = var.flowlog_configuration

  depends_on = [azurerm_virtual_hub.main]
}
