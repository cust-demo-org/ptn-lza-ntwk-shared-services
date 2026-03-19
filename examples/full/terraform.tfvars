# ──────────────────────────────────────────────────────────────
# Full Example – All Features Enabled
# ──────────────────────────────────────────────────────────────
# Demonstrates every feature in a single deployment. Dynamic
# resource IDs (hub VNet, DNS zones, NW, public IP) are computed
# in main.tf locals from inline resources. The flow-log storage
# account is created by the pattern module's storage_accounts variable.
# ──────────────────────────────────────────────────────────────

location = "southeastasia"

tags = {
  Environment = "FullExample"
  ManagedBy   = "Terraform"
  CostCenter  = "12345"
  Example     = "full"
}


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

  diagnostic_settings = {
    to_law = {
      name              = "law-diag-to-self"
      metric_categories = ["AllMetrics"]
    }
  }
}

# ─── NSGs ────────────────────────────────────────────────────

network_security_groups = {
  nsg_app = {
    name               = "nsg-app-full"
    resource_group_key = "rg_networking"

    diagnostic_settings = {
      to_law = {
        name       = "nsg-app-diag"
        log_groups = ["allLogs"]
      }
    }

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

    diagnostic_settings = {
      to_law = {
        name       = "nsg-pe-diag"
        log_groups = ["allLogs"]
      }
    }
  }
  nsg_bastion = {
    name               = "nsg-bastion-full"
    resource_group_key = "rg_networking"

    diagnostic_settings = {
      to_law = {
        name       = "nsg-bastion-diag"
        log_groups = ["allLogs"]
      }
    }

    security_rules = {
      allow_gateway_manager_inbound = {
        name                       = "AllowGatewayManager"
        priority                   = 2702
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "GatewayManager"
        destination_address_prefix = "*"
      }
      allow_https_inbound = {
        name                       = "AllowHttpsInbound"
        priority                   = 2703
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
      }
      allow_ssh_rdp_outbound = {
        name                       = "AllowSshRdpOutbound"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["22", "3389"]
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
      }
      allow_azure_cloud_outbound = {
        name                       = "AllowAzureCloudOutbound"
        priority                   = 110
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "AzureCloud"
      }
    }
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

    diagnostic_settings = {
      to_law = {
        name              = "vnet-spoke-diag"
        log_groups        = ["allLogs"]
        metric_categories = ["AllMetrics"]
      }
    }

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
        name                       = "AzureBastionSubnet"
        address_prefix             = "10.1.255.0/26"
        network_security_group_key = "nsg_bastion"
      }
    }
  }
}

# ─── Private DNS Zones ──────────────────────────────────────
# Created by the pattern module and linked to the spoke VNet.
# PE configurations reference these zone keys via private_dns_zone.keys.

private_dns_zones = {
  dns_blob = {
    domain_name        = "privatelink.blob.core.windows.net"
    resource_group_key = "rg_networking"
    virtual_network_links = {
      link_to_spoke = {
        name                = "link-blob-to-spoke"
        virtual_network_key = "vnet_spoke"
      }
    }
  }
}

byo_private_dns_zone_links = {
  link_kv_to_spoke = {
    name                = "link-kv-to-spoke"
    private_dns_zone_id = "placeholder" # overridden in main.tf with computed azurerm_private_dns_zone.kv.id
    virtual_network_key = "vnet_spoke"
  }
}

# ─── Managed Identities ─────────────────────────────────────

managed_identities = {
  mi_app = {
    name               = "mi-shared-full"
    resource_group_key = "rg_shared"
  }
}

# ─── Key Vaults ─────────────────────────────────────────────
# Private endpoint subnet and DNS zone are resolved by the pattern module
# using vnet_key/subnet_key and private_dns_zones/byo_private_dns_zone_links keys.

key_vaults = {
  kv_shared = {
    name               = "kv-shared-full"
    resource_group_key = "rg_shared"
    sku_name           = "premium"
    name_random_suffix_configuration = {
      length             = 4
      append_with_hyphen = true
    }

    diagnostic_settings = {
      to_law = {
        name              = "kv-shared-diag"
        log_groups        = ["allLogs"]
        metric_categories = ["AllMetrics"]
      }
    }

    role_assignments = {
      kv_secrets_user = {
        role_definition_id_or_name = "Key Vault Secrets User"
        managed_identity_key       = "mi_app"
      }
      kv_admin_caller = {
        role_definition_id_or_name = "Key Vault Administrator"
        assign_to_caller           = true
      }
    }

    private_endpoints = {
      pe_kv = {
        name = "pe-kv-shared-full"
        network_configuration = {
          vnet_key   = "vnet_spoke"
          subnet_key = "snet_pe"
        }
        private_dns_zone = {
          keys = ["link_kv_to_spoke"]
        }
      }
    }
  }
}

# ─── Standalone Role Assignments ─────────────────────────────
# scope is overridden in main.tf locals with computed spoke RG ID.

role_assignments = {
  ra_spoke_rg_reader = {
    role_definition_id_or_name = "Reader"
    scope                      = "placeholder" # overridden in main.tf with computed spoke RG ID
    managed_identity_key       = "mi_app"
  }
}

# ─── Bastion Hosts ──────────────────────────────────────────
# Bastion subnet is resolved by the pattern module using vnet_key/subnet_key.
# Public IP is created by inline resource and passed via public_ip_address_id.

bastion_hosts = {
  bastion_full = {
    name               = "bastion-full"
    resource_group_key = "rg_networking"
    sku                = "Standard"
    zones              = []

    diagnostic_settings = {
      to_law = {
        name              = "bastion-diag"
        log_groups        = ["allLogs"]
        metric_categories = ["AllMetrics"]
      }
    }

    ip_configuration = {
      network_configuration = {
        vnet_key   = "vnet_spoke"
        subnet_key = "AzureBastionSubnet"
      }
      create_public_ip = true
    }

    copy_paste_enabled     = true
    ip_connect_enabled     = true
    tunneling_enabled      = true
    file_copy_enabled      = true
    shareable_link_enabled = false
  }
}

# ─── Storage Accounts ────────────────────────────────────────
# Flow-log storage account created by the pattern module.

storage_accounts = {
  sa_flowlog = {
    name                          = "saflowlogfull"
    resource_group_key            = "rg_shared"
    account_replication_type      = "LRS"
    shared_access_key_enabled     = false
    public_network_access_enabled = true
    name_random_suffix_configuration = {
      length = 4
    }

    diagnostic_settings = {
      to_law = {
        name              = "sa-flowlog-diag"
        metric_categories = ["Transaction"]
      }
    }

    diagnostic_settings_blob = {
      to_law = {
        name              = "sa-blob-diag"
        log_groups        = ["allLogs"]
        metric_categories = ["Capacity", "Transaction"]
      }
    }

    diagnostic_settings_file = {
      to_law = {
        name              = "sa-file-diag"
        log_groups        = ["allLogs"]
        metric_categories = ["Capacity", "Transaction"]
      }
    }

    diagnostic_settings_queue = {
      to_law = {
        name              = "sa-queue-diag"
        log_groups        = ["allLogs"]
        metric_categories = ["Capacity", "Transaction"]
      }
    }

    diagnostic_settings_table = {
      to_law = {
        name              = "sa-table-diag"
        log_groups        = ["allLogs"]
        metric_categories = ["Capacity", "Transaction"]
      }
    }
  }
}

# ─── Network Watcher / Flow Logs ────────────────────────────
# NOTE: The AVM network_watcher module performs a data lookup for an existing
# Network Watcher. Azure auto-creates NetworkWatcher_<region> in
# NetworkWatcherRG when VNets are deployed. To enable flow logs, first deploy
# without flowlog_configuration, then uncomment the block below after the
# auto-created Network Watcher exists.
#
# The network_watcher_id, network_watcher_name, and resource_group_name fields
# are optional — they default to the Azure standard NetworkWatcherRG /
# NetworkWatcher_<location>.
#
# flowlog_configuration = {
#   flow_logs = {
#     fl_spoke_vnet = {
#       enabled  = true
#       name     = "fl-spoke-vnet"
#       vnet_key = "vnet_spoke"
#       storage_account = {
#         key = "sa_flowlog"
#       }
#       retention_policy = {
#         enabled = true
#         days    = 90
#       }
#       traffic_analytics = {
#         enabled             = true
#         interval_in_minutes = 10
#       }
#       version = 2
#     }
#   }
# }
