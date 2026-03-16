# Quickstart: ALZ Spoke Networking & Shared Services Pattern

**Branch**: `001-spoke-shared-services` | **Date**: 2026-03-09

## Prerequisites

1. **Terraform CLI** >= 1.13 installed ([install guide](https://developer.hashicorp.com/terraform/install))
2. **Azure CLI** authenticated (`az login`)
3. **Target subscription** set:
   ```bash
   export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
   ```
   Or: `az account set --subscription "<your-subscription-id>"`
4. **Terraform backend** configured (recommended: Azure Storage Account with state locking)
5. **Existing hub VNet** or **Virtual WAN Hub** resource ID (if connectivity is needed)
6. **Existing Private DNS Zones** resource IDs (if BYO DNS zone links are needed), or use the `private_dns_zones` variable to create zones within the pattern

## Step 1: Clone and Configure

```bash
git clone https://github.com/<org>/ptn-lza-ntwk-shared-services.git
cd ptn-lza-ntwk-shared-services
```

## Step 2: Edit terraform.tfvars

Copy the example and customise:

```bash
cp examples/minimal/terraform.tfvars terraform.tfvars
```

### Minimal Example (Spoke VNet with Hub Peering)

```hcl
# --------------------------------------------------------------------------
# Global
# --------------------------------------------------------------------------
location = "uksouth"
tags = {
  environment = "dev"
  project     = "landing-zone-spoke-01"
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
# Virtual Networks
# --------------------------------------------------------------------------
virtual_networks = {
  "vnet-spoke" = {
    name                    = "vnet-spoke-01"
    resource_group_key      = "rg-networking"
    address_space           = ["10.1.0.0/16"]
    subnets = {
      "snet-app" = {
        name                       = "snet-app"
        address_prefixes           = ["10.1.1.0/24"]
        network_security_group_key = "nsg-app"    # optional
        route_table_key            = "rt-default"  # optional
      }
      "snet-data" = {
        name                       = "snet-data"
        address_prefixes           = ["10.1.2.0/24"]
        network_security_group_key = "nsg-data"    # optional
        route_table_key            = "rt-default"  # optional
      }
    }
    # Omit 'peerings' entirely (or set peerings = {}) and omit vhub_connectivity_definitions for an isolated spoke VNet with no hub connectivity
    peerings = {
      "peer-to-hub" = {
        name                               = "peer-spoke01-to-hub"
        remote_virtual_network_resource_id = "/subscriptions/<hub-sub>/resourceGroups/<hub-rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>"
        allow_forwarded_traffic            = true  # default: true
        allow_gateway_transit              = false # default: false
        allow_virtual_network_access       = true  # default: true
        use_remote_gateways                = false # default: false
        create_reverse_peering             = false # default: false — set true to auto-create hub→spoke peering
      }
    }
  }
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
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
      }
    }
  }
  "nsg-data" = {
    name               = "nsg-data"
    resource_group_key = "rg-networking"
    security_rules     = {}  # no custom rules — only Azure built-in defaults apply
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
        next_hop_in_ip_address = "10.0.0.4"  # Hub firewall private IP
      }
    }
  }
}
```

## Step 3: Initialise Terraform

```bash
terraform init
```

Configure your state backend in `terraform.tf` or via `-backend-config` flags.

## Step 4: Validate and Plan

```bash
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
```

Review the plan output. Verify:
- Resource group, VNet, subnets, NSGs, route tables, peering are created  <!-- SC-001 -->
- NSGs are created with user-defined security rules only (no auto-injected rules)  <!-- FR-008 -->
- No public endpoints are exposed  <!-- SC-003 -->
- Diagnostic settings route to the Log Analytics workspace  <!-- FR-028 -->

> **Note:** SC-002 (idempotency) is verified in Step 6. SC-004 (quality gates), SC-005 (AVM modules), SC-006 (dual instantiation), and SC-008 (variable descriptions) are verified at CI/review time.

## Step 5: Apply

```bash
terraform apply tfplan
```

## Step 6: Verify Idempotency

```bash
terraform plan
```

Expected output: **"No changes. Your infrastructure matches the configuration."**

## Common Scenarios

### Adding Private DNS Zones (Created by Pattern)

Create Private DNS Zones as part of the pattern module and optionally link them to spoke VNets:

```hcl
private_dns_zones = {
  "blob" = {
    domain_name        = "privatelink.blob.core.windows.net"
    resource_group_key = "rg-networking"
    virtual_network_links = {
      "link-spoke" = {
        name                 = "link-blob-to-spoke"
        virtual_network_key  = "vnet-spoke"
        registration_enabled = false
        # resolution_policy  = "Default"  # optional — "Default" or "NxDomainRedirect"
      }
    }
  }
  "sql" = {
    domain_name        = "privatelink.database.windows.net"
    resource_group_key = "rg-networking"
    virtual_network_links = {
      "link-spoke" = {
        name                = "link-sql-to-spoke"
        virtual_network_key = "vnet-spoke"
      }
    }
  }
}
```

### Adding BYO Private DNS Zone Links

Link existing (externally managed) Private DNS Zones to the spoke VNet:

```hcl
byo_private_dns_zone_links = {
  "blob" = {
    private_dns_zone_id  = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    virtual_network_key  = "vnet-spoke"
    registration_enabled = false
    # resolution_policy  = "Default"  # optional — "Default" or "NxDomainRedirect"
  }
  "sql" = {
    private_dns_zone_id  = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"
    virtual_network_key  = "vnet-spoke"
    registration_enabled = false
  }
}
```

### Enabling Azure Bastion

Add to the VNet subnets and enable the feature flag:

```hcl
# In the virtual_networks map, add AzureBastionSubnet:
virtual_networks = {
  "vnet-spoke" = {
    # ... existing config ...
    subnets = {
      # ... existing subnets ...
      "AzureBastionSubnet" = {
        name             = "AzureBastionSubnet"
        address_prefixes = ["10.1.255.0/26"]  # minimum /26 required by Azure
      }
    }
  }
}

bastion_hosts = {
  bastion_spoke_01 = {
    name               = "bas-spoke-01"
    resource_group_key = "rg-networking"
    sku                = "Standard"  # "Basic", "Standard", "Developer", or "Premium"
    ip_configuration = {
      subnet_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/AzureBastionSubnet"
    }
  }
}
```

### Switching to vWAN Connectivity

Instead of (or in addition to) hub VNet peering, connect spoke VNets to a vWAN hub.
Add to `terraform.tfvars`:

```hcl
vhub_connectivity_definitions = {
  "vhub-conn-spoke01" = {
    vhub_resource_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualHubs/<hub-name>"
    virtual_network = {
      key = "vnet-spoke"  # references a key in virtual_networks map
      # id = "/subscriptions/..."  # alternative — use for VNets not managed by this module
    }
    internet_security_enabled = true  # default: true — routes internet traffic through hub firewall
  }
}
```

### Adding Key Vault with Managed Identity

```hcl
managed_identities = {
  "identity-app-01" = {
    name               = "id-app-01"
    resource_group_key = "rg-networking"
  }
}

key_vaults = {
  "kv-spoke" = {
    name               = "kv-spoke-01"
    resource_group_key = "rg-networking"
    role_assignments = {
      "app-secrets-officer" = {
        role_definition_id_or_name = "Key Vault Secrets Officer"
        # principal_id             = "<principal_id>"    # direct principal_id of MSI, service principal, or user
        managed_identity_key       = "identity-app-01"   # only for referencing MSI created in this pattern
      }
    }
  }
}
```

### Standalone Role Assignments

Assign roles at arbitrary scopes (e.g., subscription, resource group) outside of AVM-managed resources:

```hcl
role_assignments = {
  "reader-on-rg" = {
    role_definition_id_or_name = "Reader"
    scope                      = "/subscriptions/<sub>/resourceGroups/<rg>"
    managed_identity_key       = "identity-app-01"  # references key in managed_identities map
    # principal_id             = "<principal_id>"    # alternative — direct principal_id of MSI, service principal, or user
  }
}
```

### Enabling Network Watcher Flow Logs

Configure VNet flow logs on an existing Network Watcher (typically auto-created by Azure per region). Add to `terraform.tfvars`:

```hcl
flowlog_configuration = {
  network_watcher_id   = "/subscriptions/<sub>/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_eastus"
  network_watcher_name = "NetworkWatcher_eastus"
  resource_group_name  = "NetworkWatcherRG"
  # location           = "eastus"  # optional — defaults to module location if omitted

  flow_logs = {
    "vnet-spoke-flow-log" = {
      enabled            = true
      name               = "flowlog-vnet-spoke"
      target_resource_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet-name>"
      storage_account_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-name>"
      retention_policy = {
        days    = 90
        enabled = true
      }
      traffic_analytics = {
        enabled               = true
        interval_in_minutes   = 10
        workspace_id          = "<law-workspace-guid>"
        workspace_region      = "eastus"
        workspace_resource_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>"
      }
    }
  }
}
```

> **Note**: Set `flowlog_configuration = null` (or omit it entirely) to disable Network Watcher flow logs. The `target_resource_id` should reference the VNet or subnet you want to monitor. The storage account must exist and be in the same region as the Network Watcher.

### Using an Existing Log Analytics Workspace

By default, the module auto-creates a Log Analytics workspace. To use a shared existing workspace instead:

```hcl
# Point to an existing workspace — skips auto-creation
log_analytics_workspace_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>"
```

### Enabling Resource Locks

Apply a lock to all root-level AVM-managed resources (does not apply to submodule resources like DNS links or vHub connections):

```hcl
lock = {
  kind = "CanNotDelete"  # "CanNotDelete" or "ReadOnly"
  name = "lock-spoke-networking"
}
```

## Quality Gates (CI)

These gates must pass on every PR:

```bash
# 1. Formatting
terraform fmt -check -recursive

# 2. Validation
terraform validate

# 3. Plan (against a CI subscription)
terraform plan

# 4. Documentation freshness
terraform-docs markdown document . --output-check

# 5. Linting
tflint --init
tflint
```
