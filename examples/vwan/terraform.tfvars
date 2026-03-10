# --------------------------------------------------------------------------
# Spoke VNet connected to a Virtual WAN Hub
# --------------------------------------------------------------------------
# This example creates a spoke VNet and connects it to a vWAN hub instead of
# using traditional hub VNet peering. Set internet_security_enabled = true
# (default) to route internet traffic through the hub firewall.
# --------------------------------------------------------------------------

location = "uksouth"
tags = {
  environment = "dev"
  project     = "landing-zone-spoke-vwan"
}

# --------------------------------------------------------------------------
# Resource Groups
# --------------------------------------------------------------------------
resource_groups = {
  "rg-networking" = {
    name = "rg-spoke-networking"
  }
}

# --------------------------------------------------------------------------
# Log Analytics (auto-create for diagnostics)
# --------------------------------------------------------------------------
log_analytics_workspace_configuration = {
  resource_group_key = "rg-networking"
}

# --------------------------------------------------------------------------
# Network Security Groups
# --------------------------------------------------------------------------
network_security_groups = {
  "nsg-app" = {
    name               = "nsg-app"
    resource_group_key = "rg-networking"
    security_rules = {
      "allow-https-inbound" = {
        name                       = "allow-https-inbound"
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
}

# --------------------------------------------------------------------------
# Route Tables
# --------------------------------------------------------------------------
route_tables = {
  "rt-default" = {
    name               = "rt-default"
    resource_group_key = "rg-networking"
    routes = {
      "default-to-firewall" = {
        name                   = "default-to-firewall"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.4"
      }
    }
  }
}

# --------------------------------------------------------------------------
# Virtual Networks — no peerings block (connectivity via vWAN instead)
# --------------------------------------------------------------------------
virtual_networks = {
  "vnet-spoke" = {
    name               = "vnet-spoke-01"
    resource_group_key = "rg-networking"
    address_space      = ["10.1.0.0/16"]
    subnets = {
      "snet-app" = {
        name                       = "snet-app"
        address_prefixes           = ["10.1.1.0/24"]
        network_security_group_key = "nsg-app"
        route_table_key            = "rt-default"
      }
    }
  }
}

# --------------------------------------------------------------------------
# vWAN Hub Connectivity — connect the spoke VNet to a vWAN hub
# --------------------------------------------------------------------------
vhub_connectivity_definitions = {
  "vhub-conn-spoke01" = {
    vhub_resource_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualHubs/<hub-name>"
    virtual_network = {
      key = "vnet-spoke" # references a key in virtual_networks map
    }
    internet_security_enabled = true # routes internet traffic through hub firewall
  }
}
