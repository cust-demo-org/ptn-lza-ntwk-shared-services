# ---------------------------------------------------------------------------
# Full Example – All Features Enabled
# ---------------------------------------------------------------------------
# Creates inline hub dependencies (VNet, DNS zones, Network Watcher, public
# IP, storage account) and deploys the pattern module exercising every
# configurable feature.
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Inline dependencies — hub VNet, DNS zones, Network Watcher, Bastion IP,
# flow-log storage
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

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_public_ip" "bastion" {
  name                = "${module.naming.public_ip.name}-bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_storage_account" "flowlog" {
  name                     = module.naming.storage_account.name_unique
  location                 = var.location
  resource_group_name      = azurerm_resource_group.hub.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# ---------------------------------------------------------------------------
# Construct computed references for spoke resources created by pattern module
# ---------------------------------------------------------------------------

locals {
  subscription_id = data.azurerm_client_config.current.subscription_id

  # Spoke resource names (from terraform.tfvars)
  spoke_rg_name   = var.resource_groups["rg_networking"].name
  spoke_vnet_name = var.virtual_networks["vnet_spoke"].name

  # Construct IDs for spoke resources that the pattern module will create
  spoke_rg_id             = "/subscriptions/${local.subscription_id}/resourceGroups/${local.spoke_rg_name}"
  spoke_vnet_id           = "${local.spoke_rg_id}/providers/Microsoft.Network/virtualNetworks/${local.spoke_vnet_name}"
  spoke_pe_subnet_id      = "${local.spoke_vnet_id}/subnets/snet-private-endpoints"
  spoke_bastion_subnet_id = "${local.spoke_vnet_id}/subnets/AzureBastionSubnet"

  # LAW resource ID (auto-created by pattern module — name from tfvars)
  law_rg_name     = var.resource_groups["rg_shared"].name
  law_name        = var.log_analytics_workspace_configuration.name
  law_resource_id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.law_rg_name}/providers/Microsoft.OperationalInsights/workspaces/${local.law_name}"

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

  # DNS zone links with computed zone IDs
  private_dns_zone_links = {
    link_blob = {
      name                = "link-blob-to-spoke"
      private_dns_zone_id = azurerm_private_dns_zone.blob.id
      virtual_network_key = "vnet_spoke"
    }
    link_kv = {
      name                = "link-kv-to-spoke"
      private_dns_zone_id = azurerm_private_dns_zone.kv.id
      virtual_network_key = "vnet_spoke"
    }
  }

  # Key vaults with computed subnet and DNS zone IDs for private endpoints
  key_vaults = {
    for k, v in var.key_vaults : k => merge(v, {
      private_endpoints = {
        for pe_k, pe in v.private_endpoints : pe_k => merge(pe, {
          subnet_resource_id            = local.spoke_pe_subnet_id
          private_dns_zone_resource_ids = [azurerm_private_dns_zone.kv.id]
        })
      }
    })
  }

  # Bastion with computed subnet and public IP
  bastion_configuration = var.bastion_configuration != null ? merge(var.bastion_configuration, {
    ip_configuration = merge(var.bastion_configuration.ip_configuration, {
      subnet_id            = local.spoke_bastion_subnet_id
      public_ip_address_id = azurerm_public_ip.bastion.id
      create_public_ip     = false
    })
  }) : null

  # Network Watcher — reference Azure auto-created NW (not inline, to avoid
  # data source lookup failures during plan)
  nw_rg_name = "NetworkWatcherRG"
  nw_name    = "NetworkWatcher_${var.location}"
  nw_id      = "/subscriptions/${local.subscription_id}/resourceGroups/${local.nw_rg_name}/providers/Microsoft.Network/networkWatchers/${local.nw_name}"

  # Flow log configuration with computed storage and VNet IDs
  flowlog_configuration = var.flowlog_configuration != null ? merge(var.flowlog_configuration, {
    network_watcher_id   = local.nw_id
    network_watcher_name = local.nw_name
    resource_group_name  = local.nw_rg_name
    flow_logs = var.flowlog_configuration.flow_logs != null ? {
      for k, v in var.flowlog_configuration.flow_logs : k => merge(v, {
        target_resource_id = local.spoke_vnet_id
        storage_account_id = azurerm_storage_account.flowlog.id
        traffic_analytics = v.traffic_analytics != null ? merge(v.traffic_analytics, {
          workspace_resource_id = local.law_resource_id
        }) : null
      })
    } : null
  }) : null

  # Standalone role assignments with computed spoke RG scope
  role_assignments = {
    for k, v in var.role_assignments : k => merge(v, {
      scope = local.spoke_rg_id
    })
  }
}

# ---------------------------------------------------------------------------
# Pattern module — spoke shared services (all features)
# ---------------------------------------------------------------------------

module "pattern" {
  source = "../.."

  location                              = var.location
  tags                                  = var.tags
  use_random_suffix                     = var.use_random_suffix
  lock                                  = var.lock
  resource_groups                       = var.resource_groups
  log_analytics_workspace_id            = var.log_analytics_workspace_id
  log_analytics_workspace_configuration = var.log_analytics_workspace_configuration
  network_security_groups               = var.network_security_groups
  route_tables                          = var.route_tables
  virtual_networks                      = local.virtual_networks
  private_dns_zone_links                = local.private_dns_zone_links
  managed_identities                    = var.managed_identities
  key_vaults                            = local.key_vaults
  role_assignments                      = local.role_assignments
  vhub_connectivity_definitions         = var.vhub_connectivity_definitions
  bastion_configuration                 = local.bastion_configuration
  flowlog_configuration                 = local.flowlog_configuration

  depends_on = [ azurerm_virtual_network.hub, azurerm_private_dns_zone.blob, azurerm_private_dns_zone.kv, azurerm_public_ip.bastion, azurerm_storage_account.flowlog ]
}
