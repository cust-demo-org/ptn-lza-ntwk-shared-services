# Research: ALZ Spoke Networking & Shared Services Pattern

**Branch**: `001-spoke-shared-services` | **Date**: 2026-03-09

## 1. AVM Module Availability & Versions

### Decision: AVM module mapping for every Azure resource type in scope

| Resource Type | AVM Module | Registry Source | Latest Version | Status |
|---|---|---|---|---|
| Resource Group | `avm-res-resources-resourcegroup` | `Azure/avm-res-resources-resourcegroup/azurerm` | **0.2.2** | Available |
| Virtual Network (+ subnets, peering) | `avm-res-network-virtualnetwork` | `Azure/avm-res-network-virtualnetwork/azurerm` | **0.17.1** | Available |
| Network Security Group | `avm-res-network-networksecuritygroup` | `Azure/avm-res-network-networksecuritygroup/azurerm` | **0.5.1** | Available |
| Route Table | `avm-res-network-routetable` | `Azure/avm-res-network-routetable/azurerm` | **0.5.0** | Available |
| Key Vault | `avm-res-keyvault-vault` | `Azure/avm-res-keyvault-vault/azurerm` | **0.10.2** | Available |
| Bastion Host | `avm-res-network-bastionhost` | `Azure/avm-res-network-bastionhost/azurerm` | **0.9.0** | Available |
| Log Analytics Workspace | `avm-res-operationalinsights-workspace` | `Azure/avm-res-operationalinsights-workspace/azurerm` | **0.5.1** | Available |
| User-Assigned Managed Identity | `avm-res-managedidentity-userassignedidentity` | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | **0.4.0** | Available |
| Private DNS Zone VNet Link (on existing zones) | `avm-res-network-privatednszone` (submodule) | `Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link` | **0.5.0** | Available (submodule) |
| Virtual Hub VNet Connection (vWAN) | `avm-ptn-alz-connectivity-virtual-wan` (submodule) | `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection` | **0.13.5** | Available (submodule) |
| Role Assignment (standalone) | `avm-res-authorization-roleassignment` | `Azure/avm-res-authorization-roleassignment/azurerm` | **0.3.0** | Available (but prefer AVM module built-in `role_assignments` interface) |

### Rationale

- Every Azure resource in scope is fully covered by an AVM module or AVM submodule. Zero custom resource blocks (`azapi_resource` or `azurerm_*`) are required.
- The `avm-res-network-privatednszone` module exposes a standalone submodule at `modules/private_dns_virtual_network_link` that creates VNet links on *existing* Private DNS Zones. It accepts `parent_id` (the existing DNS zone resource ID) and `virtual_network_id` — no zone creation required. Internally uses `azapi_resource` (`Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01`).
- The `avm-ptn-alz-connectivity-virtual-wan` module exposes a standalone submodule at `modules/virtual-network-connection` that creates Virtual Hub VNet connections. It accepts a `virtual_network_connections` map with `virtual_hub_id` and `remote_virtual_network_id`. Internally uses `azurerm_virtual_hub_connection`. The module is actively maintained (v0.13.5, published 2026-01-13).
- Standalone role assignments at arbitrary scopes (not on a specific AVM-managed resource) should use the AVM `avm-res-authorization-roleassignment` module. However, for role assignments scoped to an AVM-managed resource (e.g., Key Vault), always prefer the built-in `role_assignments` interface within that module.

### Alternatives considered

- **Direct `azapi_resource` for DNS zone VNet links**: Rejected — the AVM submodule `private_dns_virtual_network_link` provides a supported, tested wrapper. Per constitution, AVM modules must be used when available.
- **Direct `azapi_resource` for Virtual Hub VNet connections**: Rejected — the AVM submodule `virtual-network-connection` from `avm-ptn-alz-connectivity-virtual-wan` provides the same capability with a standard interface.
- **`azurerm_private_dns_zone_virtual_network_link`**: Rejected — direct azurerm resources are forbidden per constitution when an AVM module exists.
- **`azurerm_virtual_hub_connection`**: Rejected — same reason.

---

## 2. VNet Peering Strategy

### Decision: Use VNet AVM module's built-in `peerings` input with `create_reverse_peering`

The `avm-res-network-virtualnetwork` v0.17.1 has a `peerings` map that supports:
- `create_reverse_peering = true/false` — creates the hub-to-spoke peering from the same module call.
- `reverse_allow_forwarded_traffic`, `reverse_allow_gateway_transit`, etc. — full control over reverse peering settings.

This maps directly to FR-012's `enable_hub_side_peering` variable:
- When `enable_hub_side_peering = false` (default): `create_reverse_peering = false`
- When `enable_hub_side_peering = true`: `create_reverse_peering = true`

### Rationale

No separate peering AVM module exists. The VNet module handles peering natively, avoiding extra resources and simplifying dependencies.

### Alternatives considered

- Separate `azapi_resource` for peering: Rejected — the VNet AVM module already handles this cleanly.

---

## 3. Connectivity Implementation

### Decision: Use implicit map-based toggles for both connectivity paths (no `connectivity_mode` enum)

- **Hub VNet peering**: Configured per-VNet via the AVM VNet module's `peerings` map within `virtual_networks[*].peerings`. Empty map (or omitted) = no peering. Each VNet can peer to a different hub independently.
- **vWAN connections**: Configured via a `vhub_connectivity_definitions` map variable. Each entry links a spoke VNet to a vWAN hub by specifying `vhub_resource_id` and a VNet reference (`key` or `id`). Empty map = no vWAN connections.
- **Both can coexist**: A VNet can have hub peering AND a vWAN connection simultaneously if needed.

### Rationale

Aligns with the FR-032 implicit map-based toggle pattern used by other optional features (`private_dns_zones`, `byo_private_dns_zone_links`, `managed_identities`, `key_vaults`). Eliminates the `connectivity_mode` enum and its associated standalone variables (`hub_virtual_network_id`, `enable_hub_side_peering`, `hub_peering_options`, `virtual_hub_id`). Per-VNet peering configuration is more flexible — different VNets can peer to different hubs. The `vhub_connectivity_definitions` variable supports multi-hub vWAN scenarios.

### Alternatives considered

- Single `connectivity_mode` enum (`none`/`hub_peering`/`vwan`): Rejected — forced mutual exclusivity between peering and vWAN, couldn't handle multi-VNet scenarios, and required standalone variables that felt disconnected from the VNet they applied to.
- Separate feature-flag booleans (`enable_hub_peering`, `enable_vwan`): Rejected — mutual exclusivity harder to enforce with two booleans, and still wouldn't solve the per-VNet targeting problem.

---

## 4. BYO Private DNS Zone VNet Links on Existing Zones

### Decision: Use AVM submodule `private_dns_virtual_network_link` from `avm-res-network-privatednszone`

Each entry in a `byo_private_dns_zone_links` map variable will create an instance of the `private_dns_virtual_network_link` submodule from `Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link`.

The submodule accepts:
- `parent_id` — the existing Private DNS Zone resource ID (e.g., `/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net`)
- `name` — the VNet link name
- `virtual_network_id` — the spoke VNet resource ID
- `registration_enabled` — auto-registration (default: `false`)
- `resolution_policy` — NxDomainRedirect support (default: `"Default"`)
- `tags`, `timeouts`, `retry` — optional

The input shape remains:
```hcl
byo_private_dns_zone_links = {
  "blob" = {
    private_dns_zone_id    = "/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net"
    registration_enabled   = false
  }
}
```

The pattern resolves `parent_id` from `private_dns_zone_id` and `virtual_network_id` from the VNet map.

### Rationale

The AVM submodule wraps `azapi_resource` (`Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01`) and can operate standalone — it only needs the existing DNS zone resource ID as `parent_id`. No zone creation required. This fully complies with Constitution Principle II (AVM Exclusive).

### Alternatives considered

- **Direct `azapi_resource`**: Rejected — AVM submodule exists and must be preferred per constitution.
- **Root `avm-res-network-privatednszone` module with `virtual_network_links` input**: Rejected — the root module requires `domain_name` and `parent_id` (resource group), meaning it creates/manages the zone itself. We only need VNet links to existing zones.
- **`azurerm_private_dns_zone_virtual_network_link`**: Rejected — direct azurerm resources forbidden when AVM module exists.

---

## 5. Naming Convention

### Decision: Use `Azure/naming/azurerm` module v0.4.3 for CAF-compliant naming

- All resource names follow CAF kebab-case conventions.
- The naming module generates name prefixes/suffixes per resource type.
- `use_random_suffix` variable (default: `false`) controls whether globally-unique resources (Key Vault) get a random suffix.
- Naming module is referenced from the Terraform Registry.

### Rationale

The `Azure/naming/azurerm` module is the de facto standard for CAF naming in Terraform. It handles resource type abbreviations and length constraints.

### Alternatives considered

- Manual naming with string interpolation: Rejected — error-prone and doesn't enforce length/character constraints.
- Custom naming module: Rejected — unnecessary when a well-maintained community module exists.

---

## 6. Diagnostic Settings Pattern

### Decision: Use each AVM module's built-in `diagnostic_settings` interface

Every AVM module in scope exposes a `diagnostic_settings` map input with a consistent shape:
```hcl
diagnostic_settings = {
  default = {
    workspace_resource_id = local.log_analytics_workspace_id
  }
}
```

The pattern computes `local.log_analytics_workspace_id` as:
- The user-provided `log_analytics_workspace_id` if non-null, OR
- The auto-created workspace's resource ID (from the `avm-res-operationalinsights-workspace` module).

This local is then passed to every AVM module's `diagnostic_settings`.

### Rationale

Using the built-in interface ensures compatibility and avoids creating separate diagnostic setting resources. All AVM modules have this interface.

### Alternatives considered

- Separate `azurerm_monitor_diagnostic_setting` resources: Rejected — duplicates functionality already in the AVM modules and violates the principle of using AVM interfaces.

---

## 7. Resource Lock Pattern

### Decision: Use each AVM module's built-in `lock` interface

Every AVM module in scope exposes a `lock` object input:
```hcl
lock = {
  kind = "CanNotDelete"
  name = "lock-name"
}
```

A pattern-level `lock` variable is passed through to each module. When `null`, no locks are applied.

### Rationale

Per user requirement, resource locks must use the AVM built-in interface, never direct `Microsoft.Authorization/locks` resources.

---

## 8. Terraform & Provider Versions

### Decision: Pin to latest stable versions

| Component | Version | Constraint |
|---|---|---|
| Terraform CLI | 1.13.3 | `>= 1.13, < 2.0` |
| azurerm provider | 4.63.0 | `~> 4.0` |
| azapi provider | 2.8.0 | `~> 2.0` (transitive via AVM modules) |

### Rationale

Terraform 1.13.x is the latest stable release with full support for ephemeral resources and write-only attributes. Provider constraints follow AVM conventions (`~> 4.0` for azurerm, `~> 2.0` for azapi). The `azapi` provider is no longer used directly in the root module — it is a transitive dependency required by several AVM modules (e.g., the `private_dns_virtual_network_link` submodule requires `azapi ~> 2.5`). The root module still declares it to ensure version compatibility across all AVM modules.

---

## 9. Role Assignment Pattern

### Decision: Use AVM module built-in `role_assignments` interface where possible; standalone `avm-res-authorization-roleassignment` for cross-resource assignments

- Key Vault role assignments → Key Vault AVM `role_assignments` input
- VNet role assignments → VNet AVM `role_assignments` input
- Subnet role assignments → VNet AVM `subnets[*].role_assignments` input
- Standalone role assignments (e.g., managed identity → subscription scope) → `avm-res-authorization-roleassignment` module

The `principal_id` in role assignment objects supports the resource reference pattern: resolve from internal managed identity map key or accept an explicit principal ID.

### Rationale

AVM built-in interfaces handle the lifecycle coupling between the resource and its role assignments. Standalone assignments are only needed for scopes not managed by an AVM module.

---

## 10. Virtual Hub VNet Connection (vWAN)

### Decision: Use AVM submodule `virtual-network-connection` from `avm-ptn-alz-connectivity-virtual-wan`

When `vhub_connectivity_definitions` is non-empty, the pattern uses the `virtual-network-connection` submodule from `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection` v0.13.5.

Each entry in `vhub_connectivity_definitions` maps to a submodule instance:
```hcl
vhub_connectivity_definitions = {
  "spoke-to-hub" = {
    vhub_resource_id = "/subscriptions/.../virtualHubs/hub-01"
    virtual_network = {
      key = "spoke-01"  # references virtual_networks map key
    }
    internet_security_enabled = true
  }
}
```

Note: The submodule defaults `internet_security_enabled` to `false`. Our pattern overrides this to `true` (secure-by-default, routing internet traffic through the hub firewall).

### Rationale

The AVM submodule wraps `azurerm_virtual_hub_connection` and provides a standard interface. Using it complies with Constitution Principle II (AVM Exclusive). The submodule requires only the connections map — it does not manage the full vWAN, hubs, or gateways. Chosen over the archived `avm-ptn-virtualwan` module because this module is actively maintained.

### Alternatives considered

- **Direct `azapi_resource`**: Rejected — AVM submodule exists; per constitution, AVM must be preferred.
- **`avm-ptn-virtualwan` submodule `vnet-conn`**: Rejected — the `avm-ptn-virtualwan` repository was archived in January 2026. The `avm-ptn-alz-connectivity-virtual-wan` module provides the same submodule interface and is actively maintained.
- **Root `avm-ptn-alz-connectivity-virtual-wan` module**: Rejected — the root module manages the entire vWAN lifecycle. We only need VNet connections to an existing hub.
- **`azurerm_virtual_hub_connection`**: Rejected — direct azurerm resources forbidden when AVM module exists.

---

## 11. Flat Root Module Structure

### Decision: Single root module with standard Terraform files

```
main.tf           # All module blocks and resource blocks
variables.tf      # All input variable declarations
outputs.tf        # All output declarations
terraform.tf      # required_version + required_providers
terraform.tfvars  # Example/default variable values
locals.tf         # Computed locals (naming, log analytics workspace ID, resource references)
_header.md        # README header content (features, usage, quickstart) — consumed by terraform-docs
_footer.md        # README footer content (contributing guide, SpecKit attribution) — consumed by terraform-docs
README.md         # Auto-generated by terraform-docs from _header.md + auto-docs + _footer.md
.terraform-docs.yml  # terraform-docs configuration (formatter: "markdown document")
```

### Rationale

Spec clarification: flat root module — AVM modules already provide sub-module abstraction. No nested sub-modules.

### Alternatives considered

- Nested sub-modules (e.g., `modules/networking/`): Rejected per spec clarification — adds unnecessary complexity when AVM modules are the abstraction layer.

---

## 12. Subscription ID Handling

### Decision: Subscription ID via environment variable or az CLI, not as a Terraform variable

The `azurerm` provider block uses no explicit `subscription_id`. The subscription is set by:
- `ARM_SUBSCRIPTION_ID` environment variable, or
- `az account set --subscription <id>` before `terraform init`

No `subscription_id` variable is exposed.

### Rationale

Per user requirement, the subscription ID must not be exposed as a variable.
