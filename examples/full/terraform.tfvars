# ──────────────────────────────────────────────────────────────
# Full Example – All Features Enabled
# ──────────────────────────────────────────────────────────────
# Demonstrates every user story and optional feature in a single
# deployment.  Adjust resource IDs and CIDR ranges for your env.
# ──────────────────────────────────────────────────────────────

location = "australiaeast"

tags = {
  Environment = "FullExample"
  ManagedBy   = "Terraform"
  CostCenter  = "12345"
}

use_random_suffix = true

lock = {
  kind = "CanNotDelete"
  name = "full-example-lock"
}

# ─── Resource Groups ────────────────────────────────────────

resource_groups = {
  rg_networking = {
    name = "rg-spoke-networking"
  }
  rg_shared = {
    name = "rg-spoke-shared-services"
  }
}

# ─── Log Analytics (auto-create) ────────────────────────────

log_analytics_workspace_id = null

log_analytics_workspace_configuration = {
  name               = "law-shared-services"
  resource_group_key = "rg_shared"
  sku                = "PerGB2018"
  retention_in_days  = 90
}

# ─── NSGs ────────────────────────────────────────────────────

network_security_groups = {
  nsg_app = {
    name               = "nsg-app-subnet"
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
    name               = "nsg-pe-subnet"
    resource_group_key = "rg_networking"
    security_rules     = {}
  }
}

# ─── Route Tables ────────────────────────────────────────────

route_tables = {
  rt_default = {
    name               = "rt-default"
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

# ─── Virtual Networks (US1) ─────────────────────────────────

virtual_networks = {
  vnet_spoke = {
    name               = "vnet-spoke-shared"
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

    peerings = {
      to_hub = {
        name                               = "spoke-to-hub"
        remote_virtual_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
        allow_forwarded_traffic            = true
        allow_gateway_transit              = false
        use_remote_gateways                = false
      }
    }
  }
}

# ─── DNS Zone Links (US2) ───────────────────────────────────

private_dns_zone_links = {
  link_blob = {
    name                = "link-blob-to-spoke"
    private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    virtual_network_key = "vnet_spoke"
  }
  link_kv = {
    name                = "link-kv-to-spoke"
    private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    virtual_network_key = "vnet_spoke"
  }
}

# ─── Managed Identities (US3) ───────────────────────────────

managed_identities = {
  mi_app = {
    name               = "mi-shared-services"
    resource_group_key = "rg_shared"
  }
}

# ─── Key Vaults (US3) ───────────────────────────────────────

key_vaults = {
  kv_shared = {
    name               = "kv-shared-svc"
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
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-networking/providers/Microsoft.Network/virtualNetworks/vnet-spoke-shared/subnets/snet-private-endpoints"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
      }
    }
  }
}

# ─── Standalone Role Assignments ─────────────────────────────

role_assignments = {
  ra_spoke_reader = {
    role_definition_id_or_name = "Reader"
    scope                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-networking"
    managed_identity_key       = "mi_app"
  }
}

# ─── vWAN Hub Connections (US4) ──────────────────────────────

vhub_connectivity_definitions = {
  conn_spoke = {
    vhub_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-connectivity/providers/Microsoft.Network/virtualHubs/vhub-australiaeast"
    virtual_network = {
      key = "vnet_spoke"
    }
    internet_security_enabled = true
  }
}

# ─── Bastion Host (US5) ─────────────────────────────────────

bastion_configuration = {
  resource_group_key = "rg_networking"
  sku                = "Standard"
  zones              = ["1", "2", "3"]

  ip_configuration = {
    subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-networking/providers/Microsoft.Network/virtualNetworks/vnet-spoke-shared/subnets/AzureBastionSubnet"
  }

  copy_paste_enabled     = true
  ip_connect_enabled     = true
  tunneling_enabled      = true
  file_copy_enabled      = true
  shareable_link_enabled = false
}

# ─── Network Watcher / Flow Logs (C3) ───────────────────────

flowlog_configuration = {
  network_watcher_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_australiaeast"
  network_watcher_name = "NetworkWatcher_australiaeast"
  resource_group_name  = "NetworkWatcherRG"

  flow_logs = {
    fl_spoke_vnet = {
      enabled            = true
      name               = "fl-spoke-vnet"
      target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-networking/providers/Microsoft.Network/virtualNetworks/vnet-spoke-shared"
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.Storage/storageAccounts/stflowlogsprod"
      retention_policy = {
        enabled = true
        days    = 90
      }
      traffic_analytics = {
        enabled               = true
        interval_in_minutes   = 10
        workspace_id          = "00000000-0000-0000-0000-000000000000"
        workspace_region      = "australiaeast"
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.OperationalInsights/workspaces/law-shared-services"
      }
      version = 2
    }
  }
}
