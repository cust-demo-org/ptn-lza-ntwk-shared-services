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
4. **Terraform state backend** pre-provisioned (Azure Storage Account with blob container and state locking)
5. **Existing hub VNet** or **Virtual WAN Hub** resource ID (if connectivity is needed)
6. **Existing Private DNS Zones** resource IDs (if DNS zone links are needed)

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
        name             = "snet-app"
        address_prefixes = ["10.1.1.0/24"]
      }
      "snet-data" = {
        name             = "snet-data"
        address_prefixes = ["10.1.2.0/24"]
      }
    }
  }
}

# --------------------------------------------------------------------------
# Connectivity (hub peering)
# --------------------------------------------------------------------------
connectivity_mode       = "hub_peering"
hub_virtual_network_id  = "/subscriptions/<hub-sub>/resourceGroups/<hub-rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>"

# --------------------------------------------------------------------------
# Network Security Groups
# --------------------------------------------------------------------------
network_security_groups = {
  "nsg-app" = {
    name               = "nsg-app"
    resource_group_key = "rg-networking"
    subnet_keys        = ["vnet-spoke/snet-app"]
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
    subnet_keys        = ["vnet-spoke/snet-data"]
    security_rules     = {}
  }
}

# --------------------------------------------------------------------------
# Route Tables
# --------------------------------------------------------------------------
route_tables = {
  "rt-default" = {
    name               = "rt-default"
    resource_group_key = "rg-networking"
    subnet_keys        = ["vnet-spoke/snet-app", "vnet-spoke/snet-data"]
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
- Resource group, VNet, subnets, NSGs, route tables, peering are created
- NSGs have a DenyAllInbound rule at priority 4096
- No public endpoints are exposed
- Diagnostic settings route to the Log Analytics workspace

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

### Adding Private DNS Zone Links

Add to `terraform.tfvars`:

```hcl
private_dns_zone_links = {
  "blob" = {
    private_dns_zone_id  = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    registration_enabled = false
  }
  "sql" = {
    private_dns_zone_id  = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"
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
        address_prefixes = ["10.1.255.0/26"]
      }
    }
  }
}

enable_bastion = true
bastion_configuration = {
  name               = "bas-spoke-01"
  resource_group_key = "rg-networking"
  virtual_network_key = "vnet-spoke"
}
```

### Switching to vWAN Connectivity

```hcl
connectivity_mode = "vwan"
virtual_hub_id    = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualHubs/<hub-name>"
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
        principal_id_reference = {
          key = "identity-app-01"
        }
      }
    }
  }
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
terraform-docs markdown table . --output-check

# 5. Linting
tflint --init
tflint
```
