# ──────────────────────────────────────────────────────────────
# Full Example – All Features Enabled
# ──────────────────────────────────────────────────────────────
# Demonstrates every feature in a single deployment. Dynamic
# resource IDs (hub VNet, DNS zones, NW, storage, public IP)
# are computed in main.tf locals from inline resources.
# ──────────────────────────────────────────────────────────────

location = "southeastasia"

tags = {
  Environment = "FullExample"
  ManagedBy   = "Terraform"
  CostCenter  = "12345"
  Example     = "full"
}

use_random_suffix = true

# ─── Resource Groups ────────────────────────────────────────

resource_groups = {
  rg_networking = {
    name = "rg-spoke-networking-full"
  }
  rg_shared = {
    name = "rg-spoke-shared-full"
  }
}

# ─── Log Analytics (auto-create) ────────────────────────────

log_analytics_workspace_configuration = {
  name               = "law-shared-full"
  resource_group_key = "rg_shared"
  sku                = "PerGB2018"
  retention_in_days  = 90
}

# ─── NSGs ────────────────────────────────────────────────────

network_security_groups = {
  nsg_app = {
    name               = "nsg-app-full"
    resource_group_key = "rg_networking"
    security_rules = {
      allow_https_inbound = {
        name                       = "AllowHTTPSInbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
      }
      deny_all_inbound = {
        name                       = "DenyAllInbound"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    }
  }
  nsg_pe = {
    name               = "nsg-pe-full"
    resource_group_key = "rg_networking"
    security_rules     = {}
  }
}

# ─── Route Tables ────────────────────────────────────────────

route_tables = {
  rt_default = {
    name               = "rt-default-full"
    resource_group_key = "rg_networking"
    routes = {
      to_firewall = {
        name                   = "to-hub-firewall"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.4"
      }
    }
  }
}

# ─── Virtual Networks ───────────────────────────────────────
# Peering to hub VNet is injected in main.tf using computed hub VNet ID.

virtual_networks = {
  vnet_spoke = {
    name               = "vnet-spoke-full"
    address_space      = ["10.1.0.0/16"]
    resource_group_key = "rg_networking"

    subnets = {
      snet_app = {
        name                       = "snet-app"
        address_prefix             = "10.1.1.0/24"
        network_security_group_key = "nsg_app"
        route_table_key            = "rt_default"
      }
      snet_pe = {
        name                              = "snet-private-endpoints"
        address_prefix                    = "10.1.2.0/24"
        network_security_group_key        = "nsg_pe"
        private_endpoint_network_policies = "Enabled"
      }
      AzureBastionSubnet = {
        name           = "AzureBastionSubnet"
        address_prefix = "10.1.255.0/26"
      }
    }
  }
}

# private_dns_zone_links — constructed in main.tf with computed DNS zone IDs

# ─── Managed Identities ─────────────────────────────────────

managed_identities = {
  mi_app = {
    name               = "mi-shared-full"
    resource_group_key = "rg_shared"
  }
}

# ─── Key Vaults ─────────────────────────────────────────────
# private_endpoints subnet_resource_id and DNS zone IDs are overridden
# in main.tf locals with computed values from inline resources.

key_vaults = {
  kv_shared = {
    name               = "kv-shared-full"
    resource_group_key = "rg_shared"
    sku_name           = "premium"

    role_assignments = {
      kv_secrets_user = {
        role_definition_id_or_name = "Key Vault Secrets User"
        managed_identity_key       = "mi_app"
      }
    }

    private_endpoints = {
      pe_kv = {
        subnet_resource_id            = "overridden-in-main-tf"
        private_dns_zone_resource_ids = ["overridden-in-main-tf"]
      }
    }
  }
}

# ─── Standalone Role Assignments ─────────────────────────────
# scope is overridden in main.tf locals with computed spoke RG ID.

role_assignments = {
  ra_spoke_reader = {
    role_definition_id_or_name = "Reader"
    scope                      = "overridden-in-main-tf"
    managed_identity_key       = "mi_app"
  }
}

# ─── Bastion Host ───────────────────────────────────────────
# ip_configuration.subnet_id and public_ip_address_id are overridden
# in main.tf locals with computed values from inline resources.

bastion_configuration = {
  resource_group_key = "rg_networking"
  sku                = "Standard"
  zones              = ["1", "2", "3"]

  ip_configuration = {
    subnet_id        = "overridden-in-main-tf"
    create_public_ip = false
  }

  copy_paste_enabled     = true
  ip_connect_enabled     = true
  tunneling_enabled      = true
  file_copy_enabled      = true
  shareable_link_enabled = false
}

# ─── Network Watcher / Flow Logs ────────────────────────────
# NOTE: The AVM network_watcher module performs a data lookup for an existing
# Network Watcher. Azure auto-creates NetworkWatcher_<region> in
# NetworkWatcherRG when VNets are deployed. To enable flow logs, first deploy
# without flowlog_configuration, then uncomment the block below after the
# auto-created Network Watcher exists.
#
# flowlog_configuration = {
#   network_watcher_id   = "overridden-in-main-tf"
#   network_watcher_name = "overridden-in-main-tf"
#   resource_group_name  = "overridden-in-main-tf"
#
#   flow_logs = {
#     fl_spoke_vnet = {
#       enabled            = true
#       name               = "fl-spoke-vnet"
#       target_resource_id = "overridden-in-main-tf"
#       storage_account_id = "overridden-in-main-tf"
#       retention_policy = {
#         enabled = true
#         days    = 90
#       }
#       traffic_analytics = {
#         enabled               = true
#         interval_in_minutes   = 10
#         workspace_id          = "00000000-0000-0000-0000-000000000000"
#         workspace_region      = "southeastasia"
#         workspace_resource_id = "overridden-in-main-tf"
#       }
#       version = 2
#     }
#   }
# }
