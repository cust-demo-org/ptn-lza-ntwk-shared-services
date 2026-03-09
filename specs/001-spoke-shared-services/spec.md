# Feature Specification: ALZ Spoke Networking & Shared Services Pattern

**Feature Branch**: `001-spoke-shared-services`
**Created**: 2026-03-09
**Status**: Draft
**Input**: User description: "Create a detailed specification for a highly reusable Terraform pattern implementing Azure ALZ spoke networking and shared services for application workloads."

## Clarifications

### Session 2026-03-09

- Q: Should the pattern support a "no connectivity" mode where no hub peering or vWAN connection is created? → A: Yes — three modes: `none`, `hub_peering`, `vwan`.
- Q: For NSG default-deny, should the pattern deny inbound only or both inbound and outbound? → A: Deny inbound only (explicit DenyAllInbound rule); outbound controlled by route table + hub firewall.
- Q: Should the pattern be a flat root module or use nested sub-modules? → A: Flat root module — AVM modules already provide the sub-module abstraction; no need for an additional nesting layer.
- Q: Does the pattern need to create the hub-side peering resource, or only the spoke-side? → A: Configurable — a variable controls whether hub-side peering is also created (default: spoke-side only).
- Q: When no existing Log Analytics workspace ID is provided, should the pattern create one or fail? → A: Auto-create a workspace by default if no existing ID is provided.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Deploy a Minimal Spoke VNet with Peering to Hub (Priority: P1)

A platform engineer creates a new application landing zone by editing a single `terraform.tfvars` file. They specify a spoke VNet address space, one or more subnets, and a reference to the existing hub VNet. After running `terraform apply`, the spoke VNet is provisioned, peered to the hub, an NSG with default-deny rules is attached to every subnet, a route table forcing traffic through the hub is associated, and diagnostic settings route logs to an existing or newly provisioned Log Analytics workspace. No public endpoints are exposed.

**Why this priority**: This is the single most common use case — every application landing zone begins with a spoke VNet peered to the hub. Without this, no downstream shared services or workloads can exist.

**Independent Test**: Deploy a spoke VNet with one subnet peered to an existing hub VNet. Verify VNet, subnet, NSG, route table, peering, and diagnostic settings exist and have expected configurations via `terraform plan` (zero drift) and Azure resource queries.

**Acceptance Scenarios**:

1. **Given** a `terraform.tfvars` file specifying a spoke VNet with one subnet and a hub VNet ID for peering, **When** `terraform apply` is executed, **Then** the spoke VNet, subnet, NSG (default-deny), route table (default route to hub), VNet peering (both directions), and diagnostic settings are created with no errors.
2. **Given** the same inputs and state from scenario 1, **When** `terraform plan` is executed again, **Then** zero changes are reported (idempotency).
3. **Given** a spoke VNet with peering, **When** no `enable_*_public_ip` flags are set to `true`, **Then** no resource exposes a public endpoint.

---

### User Story 2 — Add Private DNS Zone Links to Spoke (Priority: P2)

A platform engineer links one or more existing Azure Private DNS Zones to the spoke VNet so that workloads in the spoke can resolve private endpoints. They specify DNS zone references (by map key or explicit resource ID) in `terraform.tfvars`.

**Why this priority**: Private DNS resolution is the second most critical capability after network connectivity. Without it, workloads cannot reach Private Link-enabled services.

**Independent Test**: Deploy a spoke VNet (from US1) and add Private DNS Zone links. Verify the VNet links exist in each specified DNS zone.

**Acceptance Scenarios**:

1. **Given** a spoke VNet and a list of Private DNS Zone references (some by map key, some by explicit resource ID), **When** `terraform apply` is executed, **Then** a VNet link is created in each DNS zone pointing to the spoke VNet.
2. **Given** a DNS zone reference specifies both a map key and an explicit resource ID, **When** the pattern resolves the reference, **Then** the explicit resource ID takes precedence and the map key is ignored.
3. **Given** a DNS zone reference specifies only a map key, **When** the map key exists in the pattern's resource map, **Then** the pattern resolves it to the correct resource ID automatically.

---

### User Story 3 — Deploy Shared Key Vault with Managed Identities (Priority: P3)

A platform engineer provisions one or more Key Vaults for the spoke landing zone (e.g., for customer-managed keys, application secrets). They also provision managed identities and RBAC role assignments. All resources are configured via `terraform.tfvars`.

**Why this priority**: Key Vault and managed identities are foundational shared services that workloads depend on for secrets and encryption, but they are downstream of network connectivity.

**Independent Test**: Deploy a Key Vault with a managed identity and role assignment. Verify Key Vault exists with private-only access, the managed identity exists, and the role assignment is scoped correctly.

**Acceptance Scenarios**:

1. **Given** a `terraform.tfvars` specifying one Key Vault and one user-assigned managed identity, **When** `terraform apply` is executed, **Then** the Key Vault is created with public network access disabled by default, a managed identity is created, and a role assignment granting the identity access to the Key Vault is created.
2. **Given** a Key Vault configuration with no explicit `public_network_access_enabled` override, **When** the pattern applies defaults, **Then** public network access is disabled (secure-by-default).

---

### User Story 4 — Deploy Spoke Connected to Virtual WAN Hub (Priority: P4)

A platform engineer deploys a spoke VNet connected to an Azure Virtual WAN (vWAN) hub instead of a traditional hub VNet. They provide the Virtual Hub resource ID in `terraform.tfvars` and set the connectivity mode to `vwan`.

**Why this priority**: vWAN is a supported alternative to hub VNet peering. Not all organisations use it, but it must be a first-class option.

**Independent Test**: Deploy a spoke VNet with a vWAN hub connection. Verify the hub virtual network connection exists.

**Acceptance Scenarios**:

1. **Given** a `terraform.tfvars` specifying connectivity mode `vwan` and a Virtual Hub resource ID, **When** `terraform apply` is executed, **Then** a Virtual Hub VNet connection is created linking the spoke to the vWAN hub.
2. **Given** connectivity mode is set to `vwan`, **When** a hub VNet peering configuration is also provided, **Then** the pattern ignores the hub VNet peering configuration (connectivity mode determines which mechanism is used).

---

### User Story 5 — Deploy Azure Bastion for Spoke Access (Priority: P5)

A platform engineer enables Azure Bastion for secure remote access to VMs in the spoke by setting `enable_bastion = true`. Bastion is deployed into a dedicated `AzureBastionSubnet` within the spoke VNet.

**Why this priority**: Bastion is a common but optional component. Many spokes share a hub-deployed Bastion; deploying Bastion per-spoke is less common, so this is lower priority.

**Independent Test**: Deploy a spoke with Bastion enabled. Verify `AzureBastionSubnet`, Bastion host, and diagnostics exist.

**Acceptance Scenarios**:

1. **Given** `enable_bastion = true` in `terraform.tfvars`, **When** `terraform apply` is executed, **Then** an `AzureBastionSubnet` is created, a Bastion host is provisioned with diagnostics enabled, and the Bastion SKU defaults to the zone-redundant option.
2. **Given** `enable_bastion = false` (default), **When** `terraform apply` is executed, **Then** no Bastion resources are created.

---

### Edge Cases

- What happens when a consumer provides an invalid map key that does not match any provisioned resource? The pattern MUST fail during `terraform plan` with a clear error message identifying the invalid key.
- What happens when a consumer provides both a map key and an explicit resource ID for the same reference? The explicit resource ID MUST take precedence; the map key is silently ignored.
- What happens when a consumer specifies zero subnets for a VNet? The pattern MUST still create the VNet (subnets are optional), allowing subnets to be added later.
- What happens when a consumer provides overlapping CIDR ranges across subnets? Terraform and the Azure provider MUST detect and reject the conflict at plan time.
- What happens when a consumer enables Bastion but does not configure an `AzureBastionSubnet` CIDR? The pattern MUST fail with a clear validation error (via `variable` validation block or `precondition`).
- What happens when `terraform apply` is run with no changes to inputs? Zero resource changes MUST be reported (idempotency).
- What happens when a consumer deploys the same pattern twice in the same subscription with different name prefixes? Both deployments MUST coexist without conflict.
- What happens when `connectivity_mode = "none"` is set? No peering or vWAN connection resources are created; the spoke VNet exists in isolation. Hub-related input variables are ignored.

## Requirements *(mandatory)*

### Functional Requirements

#### Infrastructure as Code

- **FR-001**: The pattern MUST be implemented entirely in Terraform (HCL). No Bash, PowerShell, Python, `null_resource`, `local-exec`, `remote-exec`, or any provisioner block is permitted.
- **FR-002**: Every Azure resource MUST be provisioned through an Azure Verified Module (AVM) when one exists; custom `azurerm_*` blocks are permitted only when no AVM module covers the resource type, documented with a tracking issue.
- **FR-003**: All AVM module versions MUST be pinned to exact versions. AVM module defaults MUST be preserved unless an override is required for security or compliance; any opinionated override MUST be documented in the variable description.

#### Resource Groups

- **FR-004**: The pattern MUST support provisioning one or more Azure resource groups, configurable via input variables.

#### Virtual Networks & Subnets

- **FR-005**: The pattern MUST support provisioning one or more spoke virtual networks with configurable address spaces.
- **FR-006**: Each VNet MUST support zero or more subnets with configurable CIDR ranges, names, service endpoints, and delegation settings.

#### Network Security Groups

- **FR-007**: The pattern MUST provision an NSG for every subnet (unless the subnet type prohibits it, e.g., `AzureBastionSubnet` has specific NSG requirements managed by Bastion AVM).
- **FR-008**: NSGs MUST enforce a default-deny inbound posture by including an explicit DenyAllInbound rule at the lowest priority. Azure implicit outbound rules are preserved; outbound traffic control is delegated to the route table and hub firewall/NVA. Additional allow rules MUST be configurable via input variables.

#### Route Tables & Routes

- **FR-009**: The pattern MUST provision route tables with configurable routes. A default route (`0.0.0.0/0`) directing traffic to the hub firewall or NVA MUST be supported and configurable.
- **FR-010**: Route table association to subnets MUST be configurable via input variables.

#### Connectivity — Hub VNet Peering

- **FR-011**: The pattern MUST support VNet peering from the spoke VNet to a hub VNet, configurable via input variables (hub VNet ID or map key reference).
- **FR-012**: The pattern MUST create the spoke-to-hub peering resource by default. An `enable_hub_side_peering` variable (default: `false`) MUST control whether the hub-to-spoke peering resource is also created. When hub-side peering is enabled, the deployer MUST have write access to the hub VNet.

#### Connectivity — Virtual WAN

- **FR-013**: The pattern MUST support three connectivity modes selectable via a `connectivity_mode` input variable: `none` (no hub connectivity), `hub_peering` (VNet peering to a hub VNet), or `vwan` (connection to a Virtual WAN hub). The default MUST be `none`.
- **FR-014**: Only one connectivity mode MUST be active at a time; the pattern MUST enforce this via a variable validation rule restricting values to `none`, `hub_peering`, or `vwan`.

#### Private DNS Zone Links

- **FR-015**: The pattern MUST support linking one or more Azure Private DNS Zones to the spoke VNet. DNS zones MUST be referenceable by map key or explicit resource ID.

#### Managed Identities

- **FR-016**: The pattern MUST support provisioning one or more user-assigned managed identities, configurable via input variables.

#### Key Vaults

- **FR-017**: The pattern MUST support provisioning one or more Azure Key Vaults. Public network access MUST default to disabled (secure-by-default).
- **FR-018**: Key Vault RBAC role assignments MUST be configurable via input variables, supporting references to managed identities by map key or explicit principal ID.

#### Azure Bastion

- **FR-019**: The pattern MUST support optional deployment of Azure Bastion, controlled by an `enable_bastion` feature-flag variable (default: `false`).
- **FR-020**: When Bastion is enabled, an `AzureBastionSubnet` MUST be provisioned and the Bastion SKU MUST default to the zone-redundant option.

#### Resource Referencing & Lookup

- **FR-021**: All inter-resource references within the pattern MUST use Terraform map keys by default (e.g., a Key Vault role assignment references a managed identity by its map key, not a hard-coded resource ID).
- **FR-022**: Consumers MAY provide an explicit Azure resource ID as a fallback for any reference. When both a map key and explicit resource ID are provided, the explicit resource ID MUST take precedence.
- **FR-023**: The input object shape for references MUST include both a `key` field (string, optional) and an `id` field (string, optional), with a validation rule requiring at least one to be present. Example:
  ```
  resource_ref = {
    key = "identity-app-01"   # resolved via internal map
    id  = null                # or explicit Azure resource ID
  }
  ```
  Precedence: if `id` is non-null, use `id`; otherwise look up `key` in the internal resource map.

#### Naming & Tagging

- **FR-024**: All resource names MUST follow Azure Cloud Adoption Framework (CAF) kebab-case conventions by default, while respecting resource-specific constraints (length, allowed characters).
- **FR-025**: Random suffixes MUST NOT be appended to resource names by default. A `use_random_suffix` variable (default: `false`) MUST control whether globally-unique resources (e.g., Key Vault) receive a random suffix.
- **FR-026**: A common `tags` map variable MUST be applied to all resources. Additional per-resource tags MUST be mergeable via input variables.

#### Diagnostics & Observability

- **FR-027**: Diagnostic settings MUST be enabled for every resource that supports them. Logs MUST be sent to a Log Analytics workspace.
- **FR-028**: The Log Analytics workspace MAY be consumed as an existing resource ID via an input variable. If no existing workspace ID is provided, the pattern MUST auto-create a Log Analytics workspace using the AVM module so that diagnostic settings always have a valid sink.

#### Configuration & Reusability

- **FR-029**: End users MUST only need to edit `terraform.tfvars` to customise the deployment. All `.tf` files MUST be reusable without modification.
- **FR-030**: All input variables MUST have a descriptive name, explicit type constraint (no `any`), a non-empty `description` attribute, and a secure default value. Sensitive values MUST be marked `sensitive = true`.
- **FR-031**: Example `.tfvars` files MUST be provided with rich inline comments explaining each variable, its object shape, and why defaults are secure.
- **FR-032**: Feature-flag variables (e.g., `enable_bastion`, `enable_dns_zone_links`) MUST be used to toggle optional components.

#### Documentation

- **FR-033**: Terraform input/output documentation MUST be generated by `terraform-docs`. AI-generated or manually curated input/output tables are forbidden.
- **FR-034**: Each module directory MUST contain a `README.md` with `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` injection markers.
- **FR-035**: A CI quality gate MUST verify `terraform-docs` output is up-to-date; stale docs MUST fail the gate.

#### Validation & Quality Gates

- **FR-036**: The following validation gates MUST pass before `terraform apply`: `terraform fmt -check -recursive`, `terraform validate`, and `terraform plan`.
- **FR-037**: A Terraform linter (tflint or equivalent) MUST be executed as an additional gate.
- **FR-038**: Quality gates MUST NOT be implemented as wrapper scripts. They MUST be direct tool invocations.

#### AVM Module Documentation

- **FR-039**: For every AVM module consumed, variable names and complex object shapes MUST be taken from that module's published README. If a variable is not confirmed from documentation, it MUST be marked `TBD` — never invented.

### Key Entities

- **Resource Group**: A container for Azure resources. Attributes: name, location, tags.
- **Virtual Network (VNet)**: An isolated network address space. Attributes: name, address space (list of CIDRs), location, DNS servers, tags.
- **Subnet**: A subdivision of a VNet. Attributes: name, CIDR, service endpoints, delegations, NSG association, route table association.
- **Network Security Group (NSG)**: A set of inbound/outbound security rules. Attributes: name, rules (priority, direction, access, protocol, ports, source/destination).
- **Route Table**: A set of network routes. Attributes: name, routes (address prefix, next hop type, next hop IP), disable BGP propagation flag.
- **VNet Peering**: A bidirectional link between two VNets. Attributes: spoke VNet reference, hub VNet reference, allow forwarded traffic, allow gateway transit, use remote gateways.
- **Virtual Hub Connection**: A link from a spoke VNet to a vWAN hub. Attributes: Virtual Hub ID, spoke VNet reference, routing configuration.
- **Private DNS Zone Link**: Binds a VNet to a Private DNS Zone for name resolution. Attributes: DNS zone reference (key or ID), VNet reference, registration enabled flag.
- **User-Assigned Managed Identity**: An Azure identity for workloads. Attributes: name, location, tags.
- **Key Vault**: A secrets/keys/certificates store. Attributes: name, SKU, public network access, soft delete, purge protection, RBAC role assignments, diagnostics.
- **Azure Bastion**: Secure remote access service. Attributes: name, SKU (zone-redundant default), subnet, diagnostics.
- **Log Analytics Workspace**: Central log sink. Attributes: name, SKU, retention days. May be provisioned internally or provided as external ID.
- **Resource Reference**: A generic input shape with `key` (string, optional) and `id` (string, optional) fields used to reference resources by internal map key or explicit Azure resource ID.

## Assumptions

- The pattern is structured as a flat root module (no nested sub-modules). Each Azure resource is already abstracted by its AVM module; an additional sub-module layer is unnecessary.
- An Azure subscription and appropriate RBAC permissions are available before deployment.
- A hub VNet or Virtual WAN hub already exists when spoke connectivity is configured.
- Private DNS Zones already exist (provisioned by a platform team) when DNS zone links are configured.
- The Terraform state backend (Azure Storage or equivalent) is pre-provisioned and supports locking.
- Consumers are familiar with Terraform CLI workflows (`init`, `plan`, `apply`).
- The pattern targets Terraform >= 1.5 and AzureRM provider >= 3.x (exact versions pinned in the pattern).
- `terraform-docs` and `tflint` are available in the CI environment.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A platform engineer can deploy a complete spoke landing zone (VNet, subnets, NSGs, route tables, peering, diagnostics) by editing only `terraform.tfvars` and running `terraform apply`, with no modifications to `.tf` files.
- **SC-002**: Consecutive `terraform apply` runs with unchanged inputs produce zero resource changes (idempotency verified).
- **SC-003**: No resource exposes a public endpoint unless an explicit opt-in variable is set to `true`.
- **SC-004**: All five quality gates (fmt, validate, plan, terraform-docs freshness, lint) pass with zero errors on every PR.
- **SC-005**: 100% of Azure resources are provisioned via AVM modules (or have documented exceptions with tracking issues).
- **SC-006**: The pattern can be instantiated twice in the same subscription with different name prefixes and zero resource conflicts.
- **SC-007**: Switching connectivity mode from hub VNet peering to vWAN (or vice versa) requires changing only input variables, not `.tf` source code.
- **SC-008**: Every input variable has a non-empty `description` attribute and every output has a non-empty `description` attribute, verified by `terraform-docs` generation.
