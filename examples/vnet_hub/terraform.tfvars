# --------------------------------------------------------------------------
# VNet Hub Peering Example
# --------------------------------------------------------------------------
# Deploys a spoke VNet with two subnets, NSGs, a route table, LAW, and
# VNet-to-VNet peering to an inline hub VNet created in main.tf.
# Peering is injected dynamically — see locals in main.tf.
# --------------------------------------------------------------------------

location = "southeastasia"

tags = {
  Environment = "dev"
  Project     = "spoke-vnet-hub-peering"
  ManagedBy   = "terraform"
  Example     = "vnet_hub"
}

# --------------------------------------------------------------------------
# Resource Groups
# --------------------------------------------------------------------------
resource_groups = {
  rg_spoke = {
    name = "rg-spoke-shared-vnethub"
  }
}

# --------------------------------------------------------------------------
# Log Analytics (auto-create for diagnostics)
# --------------------------------------------------------------------------
log_analytics_workspace_configuration = {
  name               = "law-spoke-shared-vnethub"
  resource_group_key = "rg_spoke"
}

# --------------------------------------------------------------------------
# Network Security Groups
# --------------------------------------------------------------------------
network_security_groups = {
  nsg_app = {
    name               = "nsg-app-vnethub"
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
    name               = "nsg-data-vnethub"
    resource_group_key = "rg_spoke"
  }
}

# --------------------------------------------------------------------------
# Route Tables
# --------------------------------------------------------------------------
route_tables = {
  rt_default = {
    name               = "rt-default-vnethub"
    resource_group_key = "rg_spoke"
    routes = {
      to_firewall = {
        name                   = "default-to-firewall"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.1.4"
      }
    }
  }
}

# --------------------------------------------------------------------------
# Virtual Networks — peering added dynamically in main.tf locals
# --------------------------------------------------------------------------
virtual_networks = {
  vnet_spoke = {
    name               = "vnet-spoke-vnethub"
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

    # Peering to hub VNet is injected in main.tf using computed hub VNet ID
  }
}
