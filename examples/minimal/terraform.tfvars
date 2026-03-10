# Minimal Spoke VNet with Hub Peering
# This example deploys a single spoke VNet with two subnets, NSGs, a route table,
# and peering to a hub VNet.

location = "australiaeast"

tags = {
  Environment = "dev"
  Project     = "spoke-shared-services"
  ManagedBy   = "terraform"
}

resource_groups = {
  rg_spoke = {
    name = "rg-spoke-shared-dev-aue"
  }
}

# Auto-create a Log Analytics workspace for diagnostic settings
log_analytics_workspace_configuration = {
  resource_group_key = "rg_spoke"
}

network_security_groups = {
  nsg_app = {
    name               = "nsg-app-dev-aue"
    resource_group_key = "rg_spoke"
    security_rules = {
      allow_https_inbound = {
        name                       = "AllowHttpsInbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
      }
    }
  }
  nsg_data = {
    name               = "nsg-data-dev-aue"
    resource_group_key = "rg_spoke"
    # Empty security_rules — only Azure built-in default rules apply
  }
}

route_tables = {
  rt_default = {
    name               = "rt-default-dev-aue"
    resource_group_key = "rg_spoke"
    routes = {
      to_firewall = {
        name                   = "default-to-firewall"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.1.4" # Replace with your hub firewall private IP
      }
    }
  }
}

virtual_networks = {
  vnet_spoke = {
    name               = "vnet-spoke-dev-aue"
    address_space      = ["10.1.0.0/16"]
    resource_group_key = "rg_spoke"

    subnets = {
      snet_app = {
        name                       = "snet-app"
        address_prefix             = "10.1.1.0/24"
        network_security_group_key = "nsg_app"
        route_table_key            = "rt_default"
      }
      snet_data = {
        name                       = "snet-data"
        address_prefix             = "10.1.2.0/24"
        network_security_group_key = "nsg_data"
        route_table_key            = "rt_default"
      }
    }

    peerings = {
      to_hub = {
        name                               = "spoke-to-hub"
        remote_virtual_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub" # Replace with your hub VNet resource ID
        allow_forwarded_traffic            = true
        allow_gateway_transit              = false
        use_remote_gateways                = false
        create_reverse_peering             = true
        reverse_allow_forwarded_traffic    = true
        reverse_allow_gateway_transit      = false
      }
    }
  }
}
