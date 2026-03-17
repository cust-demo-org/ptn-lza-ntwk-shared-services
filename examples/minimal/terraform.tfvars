# Minimal Spoke VNet
# This example deploys a single spoke VNet with two subnets, NSGs, a route table,
# and a Log Analytics workspace. No peering — see vnet_hub/ or vwan_hub/ examples.

location = "southeastasia"

tags = {
  Environment = "dev"
  Project     = "spoke-shared-services"
  ManagedBy   = "terraform"
  Example     = "minimal"
}

resource_groups = {
  rg_spoke = {
    name = "rg-spoke-shared-min"
  }
}

# Auto-create a Log Analytics workspace for diagnostic settings
log_analytics_workspace_configuration = {
  name               = "law-spoke-shared-min"
  resource_group_key = "rg_spoke"
}

network_security_groups = {
  nsg_app = {
    name               = "nsg-app-min"
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
    name               = "nsg-data-min"
    resource_group_key = "rg_spoke"
    # Empty security_rules — only Azure built-in default rules apply
  }
}

route_tables = {
  rt_default = {
    name               = "rt-default-min"
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
    name               = "vnet-spoke-min"
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

    # No peerings — minimal example; see vnet_hub/ for peering
  }
}
