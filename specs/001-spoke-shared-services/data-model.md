# Data Model: ALZ Spoke Networking & Shared Services Pattern

**Branch**: `001-spoke-shared-services` | **Date**: 2026-03-09

## Entity Relationship Overview

```
Resource Group 1───* Virtual Network
Virtual Network 1───* Subnet
Virtual Network 1───0..1 VNet Peering (hub_peering mode)
Virtual Network 1───0..1 Virtual Hub Connection (vwan mode)
Virtual Network 1───* Private DNS Zone Link
Subnet *───1 Network Security Group
Subnet *───0..1 Route Table
Resource Group 1───* Key Vault
Resource Group 1───* User-Assigned Managed Identity
Resource Group 1───0..1 Azure Bastion
Resource Group 1───0..1 Log Analytics Workspace (auto-created)
Key Vault 1───* Role Assignment (via AVM interface)
User-Assigned Managed Identity ───* Role Assignment (via AVM interface or standalone)
```

## Entity Definitions

### Resource Group

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | CAF-generated | Name following CAF kebab-case convention. |
| location | `string` | Yes | — | Azure region. |
| tags | `map(string)` | No | `{}` | Merged with common tags. |
| lock | `object({kind, name})` | No | `null` | Resource lock via AVM interface. |

**AVM Module**: `Azure/avm-res-resources-resourcegroup/azurerm` v0.2.2
**Map Key**: User-defined key in `resource_groups` input variable.

---

### Virtual Network

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | CAF-generated | VNet name. |
| address_space | `set(string)` | Yes | — | List of CIDR ranges. |
| location | `string` | Yes | Inherited from RG | Azure region. |
| dns_servers | `object({dns_servers})` | No | `null` | Custom DNS server IPs. |
| resource_group_key | `string` | Yes | — | Map key referencing a resource group. |
| subnets | `map(object)` | No | `{}` | See Subnet entity. |
| peerings | `map(object)` | No | `{}` | Computed from connectivity config. |
| ddos_protection_plan | `object({id, enable})` | No | `null` | DDoS plan association. |
| diagnostic_settings | `map(object)` | No | Computed | Auto-populated with Log Analytics workspace ID. |
| lock | `object({kind, name})` | No | `null` | Resource lock via AVM interface. |
| tags | `map(string)` | No | `{}` | Merged with common tags. |
| role_assignments | `map(object)` | No | `{}` | Via AVM interface. |

**AVM Module**: `Azure/avm-res-network-virtualnetwork/azurerm` v0.17.1
**Map Key**: User-defined key in `virtual_networks` input variable.
**Dependencies**: Resource Group (parent_id).

---

### Subnet

Subnets are nested within the Virtual Network entity's `subnets` map.

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | — | Subnet name. |
| address_prefix | `string` | Conditional | — | Single CIDR. One of `address_prefix` or `address_prefixes` required. |
| address_prefixes | `list(string)` | Conditional | — | Multiple CIDRs. |
| network_security_group | `object({id})` | No | Computed | NSG ID, auto-linked by the pattern. |
| route_table | `object({id})` | No | Computed | Route table ID, auto-linked by the pattern. |
| service_endpoints_with_location | `list(object)` | No | `[]` | Service endpoints. |
| delegations | `list(object)` | No | `[]` | Subnet delegations. |
| default_outbound_access_enabled | `bool` | No | `false` | Internet outbound access (disabled by default for security). |
| private_endpoint_network_policies | `string` | No | `"Enabled"` | PE network policies. |
| role_assignments | `map(object)` | No | `{}` | Via AVM interface. |

**Not a standalone entity** — nested in VNet AVM module's `subnets` input.

---

### Network Security Group

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | CAF-generated | NSG name. |
| resource_group_name | `string` | Yes | Resolved from RG | Resource group name. |
| location | `string` | Yes | Inherited from RG | Azure region. |
| security_rules | `map(object)` | No | DenyAllInbound default | Default-deny rule + user-defined rules. |
| diagnostic_settings | `map(object)` | No | Computed | Auto-populated with Log Analytics workspace ID. |
| lock | `object({kind, name})` | No | `null` | Resource lock via AVM interface. |
| tags | `map(string)` | No | `{}` | Merged with common tags. |
| role_assignments | `map(object)` | No | `{}` | Via AVM interface. |

**AVM Module**: `Azure/avm-res-network-networksecuritygroup/azurerm` v0.5.1
**Map Key**: Derived from VNet key + subnet key (e.g., `"vnet-spoke-01_subnet-app-01"`).
**Dependencies**: Resource Group.
**State Transition**: Created → Associated with subnet (via VNet module's `subnets[*].network_security_group.id`).

---

### Route Table

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | CAF-generated | Route table name. |
| resource_group_name | `string` | Yes | Resolved from RG | Resource group name. |
| location | `string` | Yes | Inherited from RG | Azure region. |
| bgp_route_propagation_enabled | `bool` | No | `true` | BGP propagation control. |
| routes | `map(object)` | No | `{}` | Route definitions. |
| subnet_resource_ids | `map(string)` | No | `{}` | Subnet associations. |
| lock | `object({kind, name})` | No | `null` | Resource lock via AVM interface. |
| tags | `map(string)` | No | `{}` | Merged with common tags. |
| role_assignments | `map(object)` | No | `{}` | Via AVM interface. |

**AVM Module**: `Azure/avm-res-network-routetable/azurerm` v0.5.0
**Map Key**: User-defined key in `route_tables` input variable.
**Dependencies**: Resource Group. Association with subnets is post-creation via `subnet_resource_ids` or VNet module `subnets[*].route_table.id`.

---

### VNet Peering

VNet peering is not a standalone entity — it is a nested configuration within the VNet AVM module's `peerings` map.

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | Computed | Peering name. |
| remote_virtual_network_resource_id | `string` | Yes | From `hub_virtual_network_id` | Hub VNet ID. |
| allow_forwarded_traffic | `bool` | No | `true` | Allow forwarded traffic. |
| allow_gateway_transit | `bool` | No | `false` | Allow gateway transit. |
| use_remote_gateways | `bool` | No | `false` | Use remote gateways. |
| create_reverse_peering | `bool` | No | `false` | Controlled by `enable_hub_side_peering`. |
| reverse_allow_forwarded_traffic | `bool` | No | `true` | Reverse peering: allow forwarded traffic. |
| reverse_allow_gateway_transit | `bool` | No | `false` | Reverse peering: allow gateway transit. |

**Condition**: Only populated when `connectivity_mode = "hub_peering"`.

---

### Virtual Hub VNet Connection

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | Computed | Connection name. |
| virtual_hub_id | `string` | Yes | From `virtual_hub_id` input | Virtual Hub resource ID. |
| remote_virtual_network_id | `string` | Yes | Resolved from VNet | Spoke VNet resource ID. |
| internet_security_enabled | `bool` | No | `true` | Enable internet security (route through hub firewall). Pattern overrides submodule default of `false`. |
| routing | `object(...)` | No | `null` | Optional routing config (associated route table, propagated routes, static routes). |

**AVM Module**: `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection` v0.13.5 (submodule).
**Condition**: Only created when `connectivity_mode = "vwan"`.
**Dependencies**: Virtual Network.

---

### Private DNS Zone Link

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | Computed | VNet link name. |
| parent_id | `string` | Yes | From `private_dns_zone_id` | Existing Private DNS Zone resource ID. |
| virtual_network_id | `string` | Yes | Resolved from VNet | Spoke VNet resource ID. |
| registration_enabled | `bool` | No | `false` | Enable auto-registration. |
| resolution_policy | `string` | No | `"Default"` | Resolution policy (`Default` or `NxDomainRedirect`). |
| tags | `map(string)` | No | `{}` | Tags. |

**AVM Module**: `Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link` v0.5.0 (submodule).
**Map Key**: User-defined key in `private_dns_zone_links` input variable.
**Dependencies**: Virtual Network.

---

### User-Assigned Managed Identity

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | CAF-generated | Identity name. |
| location | `string` | Yes | Inherited from RG | Azure region. |
| resource_group_key | `string` | Yes | — | Map key referencing a resource group. |
| lock | `object({kind, name})` | No | `null` | Resource lock via AVM interface. |
| tags | `map(string)` | No | `{}` | Merged with common tags. |

**AVM Module**: `Azure/avm-res-managedidentity-userassignedidentity/azurerm` v0.4.0
**Map Key**: User-defined key in `managed_identities` input variable.
**Dependencies**: Resource Group.

---

### Key Vault

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | CAF-generated | Key Vault name. |
| resource_group_key | `string` | Yes | — | Map key referencing a resource group. |
| location | `string` | Yes | Inherited from RG | Azure region. |
| sku_name | `string` | No | `"premium"` | AVM default. |
| public_network_access_enabled | `bool` | No | `false` | Secure-by-default override of AVM default (`true`). |
| network_acls | `object(...)` | No | `{default_action = "Deny"}` | Firewall rules. |
| purge_protection_enabled | `bool` | No | `true` | AVM default preserved. |
| role_assignments | `map(object)` | No | `{}` | Via AVM interface. Principal ID resolved from managed identity map key or explicit ID. |
| private_endpoints | `map(object)` | No | `{}` | Via AVM interface. |
| diagnostic_settings | `map(object)` | No | Computed | Auto-populated with Log Analytics workspace ID. |
| lock | `object({kind, name})` | No | `null` | Resource lock via AVM interface. |
| tags | `map(string)` | No | `{}` | Merged with common tags. |

**AVM Module**: `Azure/avm-res-keyvault-vault/azurerm` v0.10.2
**Map Key**: User-defined key in `key_vaults` input variable.
**Dependencies**: Resource Group, Managed Identity (for role assignments).
**Secure-by-default override**: `public_network_access_enabled = false` (AVM default is `true`).

---

### Azure Bastion

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | CAF-generated | Bastion host name. |
| location | `string` | Yes | Inherited from RG | Azure region. |
| sku | `string` | No | `"Standard"` | SKU (Basic/Standard/Developer/Premium). Standard supports zone-redundancy. |
| zones | `set(string)` | No | `["1","2","3"]` | AVM default — zone-redundant. |
| ip_configuration | `object(...)` | Yes | Computed | Subnet ID from AzureBastionSubnet. |
| diagnostic_settings | `map(object)` | No | Computed | Auto-populated with Log Analytics workspace ID. |
| lock | `object({kind, name})` | No | `null` | Resource lock via AVM interface. |
| tags | `map(string)` | No | `{}` | Merged with common tags. |
| role_assignments | `map(object)` | No | `{}` | Via AVM interface. |

**AVM Module**: `Azure/avm-res-network-bastionhost/azurerm` v0.9.0
**Condition**: Only created when `enable_bastion = true`.
**Dependencies**: Virtual Network (AzureBastionSubnet must exist), Resource Group.
**Validation**: `AzureBastionSubnet` CIDR must be provided when Bastion is enabled.

---

### Log Analytics Workspace

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| name | `string` | Yes | CAF-generated | Workspace name. |
| location | `string` | Yes | Inherited from RG | Azure region. |
| resource_group_key | `string` | Yes | — | Map key referencing a resource group. |
| lock | `object({kind, name})` | No | `null` | Resource lock via AVM interface. |
| tags | `map(string)` | No | `{}` | Merged with common tags. |

**AVM Module**: `Azure/avm-res-operationalinsights-workspace/azurerm` v0.5.1
**Condition**: Only created when `log_analytics_workspace_id` is not provided.
**Dependencies**: Resource Group.

---

### Resource Reference (Generic Input Shape)

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| key | `string` | Conditional | `null` | Map key referencing an internally provisioned resource. |
| id | `string` | Conditional | `null` | Explicit Azure resource ID. |

**Validation**: At least one of `key` or `id` must be non-null. If `id` is non-null, it takes precedence over `key`.

**Usage pattern** (Terraform pseudo-code):
```hcl
resolved_id = coalesce(ref.id, local.resource_map[ref.key].resource_id)
```

---

## Deployment Order

```
1. Resource Groups
2. Log Analytics Workspace (if auto-created)
3. Network Security Groups
4. Route Tables
5. Virtual Networks (with subnets referencing NSG/RT IDs, and peering config)
6. Private DNS Zone Links (depends on VNet)
7. Virtual Hub VNet Connection (depends on VNet, if vwan mode)
8. User-Assigned Managed Identities
9. Key Vaults (with role assignments referencing identity principal IDs)
10. Azure Bastion (depends on VNet AzureBastionSubnet)
```

Dependencies are expressed through Terraform implicit references (resource attributes). Explicit `depends_on` is not needed because:
- VNet references NSG and RT by `id` → implicit dependency.
- Key Vault role assignments reference managed identity `principal_id` → implicit dependency.
- Bastion references subnet `id` → implicit dependency.
