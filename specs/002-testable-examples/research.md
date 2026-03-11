# Research: Testable Examples

**Feature**: 002-testable-examples | **Date**: 2026-03-10

## R1: AVM Example Pattern (variables.tf + terraform.tfvars)

**Decision**: Each example exposes all pattern module variables via `variables.tf` with defaults; `terraform.tfvars` provides scenario-specific overrides. Dependent resources (RG, hub VNet, vWAN, etc.) are hardcoded in `main.tf`.

**Rationale**: The AVM convention (reference: [terraform-azurerm-avm-res-network-firewallpolicy](https://github.com/Azure/terraform-azurerm-avm-res-network-firewallpolicy)) uses this pattern: examples declare variables with defaults so `terraform plan` works with no inputs, while `.tfvars` provides real deployment values. This enables both zero-input CI testing and realistic deployments with custom values.

**Alternatives considered**:
- Hardcode all values in `main.tf` (original spec approach) — Rejected: doesn't test the variable interface; consumers can't see how to override values.
- Only use `.tfvars` with no `variables.tf` — Rejected: `terraform plan` would require `-var-file` flag, violating the "no required inputs" convention.

## R2: Provider Version Pinning Strategy

**Decision**: Examples pin providers to exact versions: `azurerm = "4.63.0"`, `azapi = "2.8.0"`, `random = "3.8.1"`. The root module retains range constraints (`~> 4.0`, `~> 2.0`, `~> 3.0`).

**Rationale**: Exact pins in examples ensure reproducible `terraform plan` output. The root module keeps range constraints for consumer flexibility. This mirrors AVM practices where examples pin versions for CI stability.

**Alternatives considered**:
- Range constraints in examples (mirrors root) — Rejected: plan output varies as providers release new versions; CI tests become flaky.
- Pin root module to exact versions — Rejected: overly restrictive for consumers who may need different minor versions.

## R3: Example Directory Taxonomy (4 Examples)

**Decision**: Four examples covering progressive feature complexity:

| Example | Purpose | Inline Dependencies | Pattern Features Tested |
|---------|---------|----------------------|------------------------|
| `minimal/` | Simplest viable deployment | RG, naming | resource_groups, log_analytics, NSGs, route_tables, VNets (no peering) |
| `vnet_hub/` | VNet-to-VNet hub peering | RG, naming, hub VNet | All minimal features + VNet peering to hub |
| `vwan_hub/` | vWAN hub connectivity | RG, naming, vWAN, vHub | All minimal features + vhub_connectivity_definitions |
| `full/` | Every optional feature | RG, naming, hub VNet, DNS zone, Network Watcher, public IP, storage account | ALL pattern features: Bastion, Key Vault, managed identities, role assignments, flow logs, DNS links, peering |

**Rationale**: The original spec had 3 examples. Adding `vnet_hub/` separates the common VNet peering scenario from the minimal case (which now omits peering entirely). Renaming `vwan/` to `vwan_hub/` clarifies it connects to a vWAN hub, not just configures a vWAN.

**Alternatives considered**:
- 3 examples (minimal with peering, full, vwan) — Rejected: minimal should be truly minimal (no peering); VNet hub peering deserves its own dedicated example.
- 5+ examples (one per feature) — Rejected: too many examples to maintain; progressive complexity with 4 is enough coverage.

## R4: AVM Variable Pass-Through Audit

**Decision**: Based on audit of all 13 AVM module calls, the following fields should be added to root module variable types (FR-021):

### High Priority (common operational patterns)

| Variable | Missing Field | AVM Module | Justification |
|----------|--------------|------------|---------------|
| `resource_groups` | `role_assignments` | resource_group v0.2.2 | Per-RG RBAC is common (e.g., Reader for monitoring, Contributor for app teams) |
| `resource_groups` | `lock` | resource_group v0.2.2 | Per-RG lock overrides allow different lock policies per RG |
| `log_analytics_workspace_configuration` | `role_assignments` | log_analytics v0.5.1 | LAW RBAC for data access control |
| `network_security_groups` | `role_assignments` | nsg v0.5.1 | Per-NSG RBAC for network team delegation |
| `managed_identities` | `role_assignments` | managed_identity v0.4.0 | Bootstrap permissions at identity creation time |

### Medium Priority (nice-to-have for completeness)

| Variable | Missing Field | AVM Module | Justification |
|----------|--------------|------------|---------------|
| `log_analytics_workspace_configuration` | `private_endpoints` | log_analytics v0.5.1 | Private Link access for LAW |
| `bastion_configuration` | `role_assignments` | bastion v0.9.0 | Per-Bastion RBAC |
| `virtual_networks` | `role_assignments` (VNet-level) | vnet v0.17.1 | Subnet-level already exposed; VNet-level is supplementary |

### Intentionally Excluded

| Variable | Field | Reason |
|----------|-------|--------|
| `private_dns_zone_links` | `lock` | Submodule doesn't support lock interface |
| `vhub_connectivity_definitions` | `tags` | Azure vHub connections don't support tagging |
| All modules | `customer_managed_key` | Scope creep — CMK is a separate feature concern |
| Route tables | `diagnostic_settings` | Auto-default diagnostic settings already applied |

**Rationale**: Focus on `role_assignments` pass-through as the most commonly needed field across modules. `lock` on resource_groups enables per-RG lock policies. Keeping diagnostic_settings as auto-configured (to LAW) is the right pattern — consumers shouldn't need to configure individual diagnostic targets.

**Alternatives considered**:
- Pass through EVERY AVM variable — Rejected: many fields (customer_managed_key, managed_identities on KV, etc.) are not applicable or would cause scope creep.
- Only add `role_assignments` to resource_groups — Rejected: user explicitly flagged this as an audit across all modules; the high-priority set covers the most useful additions.

## R5: Variable Description Improvement Pattern (FR-020)

**Decision**: Root module variable descriptions will use multi-line heredoc format (`<<-EOT ... EOT`) referencing the specific AVM module and variable they map to.

**Example pattern**:
```hcl
variable "resource_groups" {
  type = map(object({
    name               = string
    location           = optional(string)
    tags               = optional(map(string), {})
    lock               = optional(object({ ... }))
    role_assignments   = optional(map(object({ ... })), {})
  }))
  description = <<-EOT
    Map of resource groups to create. The map key is used as a reference key for other resources.

    Uses: Azure/avm-res-resources-resourcegroup/azurerm v0.2.2
    See: https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm

    - name:             Resource group name.
    - location:         Azure region. Defaults to var.location if not specified.
    - tags:             Per-resource-group tags, merged with var.tags.
    - lock:             Per-resource-group lock override. Defaults to var.lock.
                        See AVM module variable: lock.
    - role_assignments: Per-resource-group RBAC assignments.
                        See AVM module variable: role_assignments.
  EOT
}
```

**Rationale**: Heredoc descriptions allow structured multi-line content visible in terraform-docs output. Referencing AVM module + variable name lets consumers trace each field back to the upstream documentation.

**Alternatives considered**:
- Single-line descriptions (current) — Rejected: insufficient for complex object types; consumers can't trace fields to AVM docs.
- External documentation only — Rejected: violates Constitution Principle VI (descriptions must be on the variable itself).

## R6: terraform-docs Configuration per Example

**Decision**: Each example gets a `_header.md` + terraform-docs generated `README.md`. No footer needed. The `_header.md` describes what the example demonstrates, following the AVM convention. terraform-docs markers (`<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->`) are used.

**Rationale**: Constitution Principle VI mandates terraform-docs for all module directories. Examples are root modules and need documented inputs/outputs for consumers.

**Alternatives considered**:
- No README in examples — Rejected: violates Constitution Principle VI.
- Manual README without terraform-docs — Rejected: documentation drifts.

## R7: Inline Dependency Strategy per Example

**Decision**: Each example deploys dependencies using `azurerm_*` resource blocks (not AVM modules) for dependent resources that exist solely to satisfy pattern module prerequisites.

| Example | Inline Resource | Purpose |
|---------|----------------|---------|
| All | `azurerm_resource_group` (or AVM naming + pattern call) | Base requirement |
| `vnet_hub/` | `azurerm_virtual_network` (hub) | Peering target for spoke VNet |
| `vwan_hub/` | `azurerm_virtual_wan`, `azurerm_virtual_hub` | vHub connectivity target |
| `full/` | `azurerm_virtual_network` (hub), `azurerm_private_dns_zone`, `azurerm_network_watcher` (if not auto-created), `azurerm_public_ip`, `azurerm_storage_account` | All feature dependencies |

**`depends_on` requirement**: When inline `azurerm_*` resources are referenced by the pattern module (via computed IDs passed through locals), the `module "pattern"` block **must** include an explicit `depends_on` listing all inline resources it depends on. This ensures Terraform creates the inline resources before the pattern module attempts to use their IDs. Examples: `depends_on = [ azurerm_virtual_network.hub ]` (vnet_hub), `depends_on = [ azurerm_virtual_hub.main ]` (vwan_hub), and the full list for `full/`. The `minimal/` example has no inline dependencies and does not need `depends_on`.

**Note**: Using `azurerm_*` for inline deps (not AVM) is acceptable per Constitution Principle II exemption: "Custom resource blocks are permitted ONLY when no AVM module exists for the resource type AND the omission is documented." In the examples context, these are ephemeral test dependencies, not pattern infrastructure. However, `azurerm_resource_group` could be replaced by an AVM naming call + the pattern module creating the RG. The decision here is that **the RG is created by the pattern module itself** (via the `resource_groups` variable), so examples only deploy resources the pattern does NOT create.

**Rationale**: Inline `azurerm_*` resources are simpler, faster, and avoid AVM module version management for ephemeral test infrastructure.
