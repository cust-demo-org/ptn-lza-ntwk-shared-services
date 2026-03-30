# --------------------------------------------------------------------------
# vWAN Hub Connectivity Example
# --------------------------------------------------------------------------
# Deploys a spoke VNet and connects it to an inline vWAN Hub (created in
# main.tf) instead of using traditional VNet peering.
# vhub_connectivity_definitions is constructed dynamically in main.tf.
# --------------------------------------------------------------------------

location = "southeastasia"
tags = {
  Environment = "dev"
  Project     = "spoke-vwan-hub"
  ManagedBy   = "terraform"
  Example     = "vwan_hub"
}

# --------------------------------------------------------------------------
# Resource Groups
# --------------------------------------------------------------------------
resource_groups = {
  rg_networking = {
    name = "rg-spoke-networking-vwanhub"
  }
}

# --------------------------------------------------------------------------
# Log Analytics (pattern-managed for diagnostics)
# --------------------------------------------------------------------------
log_analytics_workspace_configuration = {
  name               = "law-spoke-vwanhub"
  resource_group_key = "rg_networking"
}

# --------------------------------------------------------------------------
# Network Security Groups
# --------------------------------------------------------------------------
network_security_groups = {
  nsg_app = {
    name               = "nsg-app-vwanhub"
    resource_group_key = "rg_networking"
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
}

# --------------------------------------------------------------------------
# Route Tables
# --------------------------------------------------------------------------
route_tables = {
  rt_default = {
    name               = "rt-default-vwanhub"
    resource_group_key = "rg_networking"
    routes = {
      to_firewall = {
        name                   = "default-to-firewall"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.4"
      }
    }
  }
}

# --------------------------------------------------------------------------
# Virtual Networks — no peerings (connectivity via vWAN instead)
# --------------------------------------------------------------------------
virtual_networks = {
  vnet_spoke = {
    name               = "vnet-spoke-vwanhub"
    resource_group_key = "rg_networking"
    address_space      = ["10.1.0.0/16"]
    subnets = {
      snet_app = {
        name                       = "snet-app"
        address_prefixes           = ["10.1.1.0/24"]
        network_security_group_key = "nsg_app"
        route_table_key            = "rt_default"
      }
    }
  }
}

# vhub_connectivity_definitions is constructed in main.tf using the
# computed azurerm_virtual_hub.main.id — see locals in main.tf.
