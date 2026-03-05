<!--
  ═══════════════════════════════════════════════════════
  SYNC IMPACT REPORT
  ═══════════════════════════════════════════════════════
  Version change : (none) → 1.0.0  [MAJOR — initial ratification]
  Bump rationale : First ratification of the constitution.

  Sections (all new — initial creation):
    - Purpose
    - Scope & Non-Scope
    - Core Principles (8 principles)
    - Quality Gates & Definition of Done
    - Governance

  Template sync status:
    .specify/templates/plan-template.md        ✅ compatible
      — "Constitution Check" section references constitution
        dynamically; no changes required.
    .specify/templates/spec-template.md         ✅ compatible
      — Generic requirement/success-criteria structure is
        technology-agnostic; no changes required.
    .specify/templates/tasks-template.md        ✅ compatible
      — Phase-based structure accommodates Terraform workflow
        phases; no changes required.
    .specify/templates/checklist-template.md    ✅ compatible
    .specify/templates/agent-file-template.md   ✅ compatible
    README.md                                   ✅ no conflict

  Follow-up TODOs: (none)
  ═══════════════════════════════════════════════════════
-->

# ALZ Network Shared Services Pattern Constitution

## Purpose

This constitution governs the design, implementation, review, and
evolution of the **Azure Application Landing Zone (ALZ) Network
Shared Services** Terraform pattern. The pattern provisions
reusable network infrastructure and shared services (spoke virtual
networks, private DNS links, bastion,
and related components) that application workloads consume within
an ALZ topology.

Every contributor, reviewer, and consumer of this pattern MUST
treat this document as the authoritative source of truth. Where
ambiguity exists between this constitution and any other project
artifact, this constitution prevails.

## Scope & Non-Scope

### In Scope

- Spoke virtual network(s) and peering configuration to hub virtual network or virtual hub and/or other virtual networks.
- Azure Bastion.
- Private DNS Zones links.
- Network security groups, route tables, and associated rules.
- DDoS Protection Plan association.
- Diagnostic settings, log analytics workspace integration. Log analytics workspace can be provisioned by this pattern or consumed as an input variable if provisioned by other methods.
- Network Watcher and flow-log configuration.
- Shared services consumed by spoke workloads (e.g., shared Key Vault for network secrets and encryption of PaaS resources with customer-managed keys, identities, role assignments).

### Non-Scope

- Application-level (spoke) workload infrastructure.
- Entra ID tenant configuration.
- Management group hierarchy or Azure Policy definitions.
- Billing, cost management, or subscription vending.
- CI/CD pipeline definition (pipelines invoke this pattern but
  are not governed by it).

## Core Principles

### I. Terraform-Only Declarative Infrastructure (NON-NEGOTIABLE)

All infrastructure MUST be expressed exclusively in HashiCorp
Configuration Language (HCL) executed by Terraform.

- Contributors MUST NOT introduce Bash, PowerShell, Python, or
  any other scripting language into the module source tree.
- The use of `null_resource`, `local-exec`, `remote-exec`, and
  any provider-level provisioner blocks is FORBIDDEN.
- External data retrieval MUST use only Terraform data sources
  or provider-native resources — never external scripts.
- Terraform version constraints MUST be pinned to a specific
  minor range (e.g., `~> 1.x`) in the root `required_version`
  block.
- Provider version constraints MUST be pinned to a specific
  minor range in `required_providers`.

**Rationale:** Declarative-only infrastructure ensures
reproducibility, auditability, and eliminates an entire class
of imperative side-effect bugs.

### II. Azure Verified Modules Exclusive (NON-NEGOTIABLE)

Every Azure resource MUST be provisioned through an official
[Azure Verified Module (AVM)](https://aka.ms/avm) when one
exists for the resource type.

- Before authoring a custom `azurerm_*` resource block, the
  contributor MUST verify that no AVM module covers the
  resource. This verification MUST be documented in the PR.
- When an AVM module exists, the pattern MUST consume it via a
  `module` block referencing the AVM registry source.
- AVM module versions MUST be pinned to a specific version
  (exact version constraint) and updated deliberately through
  a reviewed pull request.
- Custom resource blocks are permitted ONLY when no AVM module
  exists for the resource type AND the omission is documented
  with a tracking issue for future AVM adoption.
- AVM module defaults MUST be preserved unless an override is
  explicitly required for security, compliance, or
  architectural reasons. Any opinionated default added on top
  of AVM MUST be documented in the variable description and
  MUST be secure-by-default.

**Rationale:** AVM modules are Microsoft-maintained,
tested, and follow a consistent interface contract. Using them
maximises supportability and reduces maintenance burden.

### III. Configuration-Driven Reusability

The pattern MUST be fully parameterised so that consumers can
deploy it across environments, subscriptions, regions, and
teams without modifying module source code.

- Every configurable aspect MUST be exposed as a Terraform
  input variable with a descriptive name, type constraint,
  and a `description` attribute.
- Variables MUST default to AVM module defaults wherever
  possible. When an opinionated default is added, it MUST be
  documented in the variable's `description` and MUST be
  secure-by-default.
- Variables MUST NOT use overly broad types (e.g., `any`).
  Prefer `object({...})`, `map(...)`, `list(...)`, or scalar
  types with explicit type constraints.
- Sensitive values MUST be marked with `sensitive = true`.
- The pattern MUST support multiple independent instantiations
  within the same Terraform state (via naming/prefix
  variables) and across separate state files.
- Feature-flag variables (e.g., `enable_bastion`) SHOULD be used to toggle optional
  components, defaulting to the most common secure
  configuration.

**Rationale:** A configuration-driven approach enables a
single codebase to serve every environment and team, reducing
drift and duplication.

### IV. Security by Default (NON-NEGOTIABLE)

The pattern MUST enforce a secure-by-default network posture.
Security requirements are non-negotiable and override
convenience in every trade-off decision.

- **Least privilege:** All managed identities, RBAC
  assignments, and network security rules MUST follow the principle of
  least privilege. Broad wildcards (`*`) in network rules or
  RBAC scopes are FORBIDDEN unless explicitly justified and
  documented.
- **Network segmentation:** The spoke network MUST enforce
  segmentation through NSGs and route tables. Default-deny MUST be the baseline posture for all
  NSGs.
- **No public exposure by default:** No resource MUST expose a
  public endpoint by default. Public endpoints MUST be opt-in
  via an explicit input variable (e.g.,
  `enable_bastion_public_ip = true`) and the variable
  description MUST state the security implication.
- **Encryption:** All data-in-transit MUST use TLS 1.2+.
  All data-at-rest MUST use platform-managed or
  customer-managed encryption as supported by AVM.
- **Logging and auditing:** Diagnostic settings MUST be
  enabled for every resource that supports them. Logs MUST be
  sent to a Log Analytics workspace (and optionally a Storage
  Account for long-term retention). This MUST be configured
  via AVM diagnostic settings interfaces.
- **DDoS Protection:** The pattern MUST support associating a
  DDoS Protection Plan with the spoke VNet. The association
  SHOULD be enabled by default when a plan ID is provided.

**Rationale:** A network shared-services layer is the trust
boundary for all workloads. A single misconfiguration here
has blast-radius across every spoke.

### V. Reliability & Determinism (NON-NEGOTIABLE)

The pattern MUST produce deterministic, repeatable deployments
and support safe, incremental updates.

- **Deterministic plans:** Given identical inputs and state, a
  `terraform plan` MUST produce an identical execution plan.
  Resources MUST NOT depend on runtime-varying external data
  (e.g., current timestamp, random values without seeds)
  unless the non-determinism is intentional and documented.
- **Safe updates:** Breaking changes to variable interfaces
  MUST follow semantic versioning (see Governance). Resources
  MUST use `lifecycle` blocks (e.g., `create_before_destroy`,
  `prevent_destroy`) where destruction would cause downtime
  or data loss, and these choices MUST be configurable via
  input variables.
- **Resiliency:** Zone-redundancy and regional-redundancy
  options MUST be exposed as configurable input variables for
  every resource that supports them (e.g., Bastion SKU). 
  The default SHOULD favour the
  zone-redundant option when available.
- **State safety:** The pattern MUST NOT use `terraform
  taint`, `terraform state rm`, or any state-manipulation
  commands as part of normal operation. State backends MUST
  support locking.
- **Idempotency:** Consecutive `terraform apply` runs with
  unchanged inputs MUST result in zero resource changes.

**Rationale:** Network infrastructure underpins all workloads.
Non-deterministic or unsafe deployments risk cascading
outages.

### VI. Tooling-Based Documentation (NON-NEGOTIABLE)

All Terraform module documentation (inputs, outputs, providers,
resources, sub-modules) MUST be generated by
[terraform-docs](https://terraform-docs.io/).

- AI-generated or manually curated Terraform input/output
  documentation is FORBIDDEN. The canonical reference for
  variables, outputs, providers, and resources MUST be the
  output of `terraform-docs`.
- Each module directory MUST contain a `README.md` with
  `terraform-docs` injection markers (e.g.,
  `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->`).
- `terraform-docs` MUST be executed as part of the CI pipeline
  or a pre-commit hook; stale documentation MUST fail the
  quality gate.
- High-level architectural guidance, usage examples, decision
  records, and diagrams MAY be authored manually and SHOULD
  reside in a `docs/` directory or in the README outside the
  `terraform-docs` injection markers.
- Every input variable MUST have a non-empty `description`
  attribute that is meaningful to a consumer who has not read
  the source code.

**Rationale:** Tooling-generated documentation is always in
sync with the code. Manual documentation drifts.

### VII. Operability & Observability

The pattern MUST be operable across environments,
subscriptions, and teams without bespoke knowledge.

- **Meaningful outputs:** The root module MUST export outputs
  for every resource ID, name, and connection-relevant
  attribute (e.g., VNet ID, subnet IDs,
  DNS zone IDs) that spoke patterns or downstream consumers
  need.
- **Output descriptions:** Every output MUST have a non-empty
  `description` attribute.
- **Naming and tagging:** All resources MUST support a
  configurable naming convention and a common tag map
  variable. A default naming convention SHOULD follow
  Microsoft Cloud Adoption Framework (CAF) recommendations.
- **Environment separation:** The pattern MUST support
  deploying identical infrastructure to different
  environments (dev, staging, prod) using only variable
  overrides — never code branches.
- **Observability integration:** The pattern MUST output the
  Log Analytics workspace ID and any relevant diagnostic
  resource IDs so that consumers can correlate telemetry.

**Rationale:** Operations teams must be able to onboard,
troubleshoot, and extend the pattern without reverse-
engineering module internals.

### VIII. Extensibility & Composability

The pattern MUST be designed for extension without
modification.

- New optional components (e.g., a new Private DNS Zone) 
  MUST be addable by providing new input
  variables and module blocks — never by editing existing
  resource blocks.
- The pattern SHOULD expose sub-module outputs so that
  consumers can compose higher-order patterns (e.g., a
  hub-and-spoke topology module that wraps this pattern).
- Cross-pattern integration points (e.g., peering, DNS
  forwarding) MUST be exposed as input/output variable
  contracts, not hard-coded resource references.
- The pattern MUST NOT hard-code subscription IDs, tenant IDs,
  resource group names, or region. These MUST be supplied via
  variables or inherited from the provider configuration.

**Rationale:** Landing zone patterns evolve. Extensibility
ensures the pattern can grow without forking.

## Quality Gates & Definition of Done

### Mandatory Quality Gates

The following gates MUST pass before any change is merged or
any deployment is initiated:

1. **`terraform fmt -check -recursive`** — All HCL files MUST
   be formatted. Non-zero exit code MUST fail the gate.
2. **`terraform validate`** — The configuration MUST pass
   validation with no errors and no warnings.
3. **`terraform plan`** — A plan MUST be generated
   successfully against a representative environment. The plan
   output MUST be reviewed for unexpected changes.
4. **`terraform-docs` freshness** — Generated documentation
   MUST be up to date. A diff check between the current
   README and a freshly generated version MUST produce no
   differences.
5. **Linting (tflint or equivalent)** — A Terraform linter
   MUST be executed with the AVM ruleset (if available). This
   MUST be a declarative tool invocation, not a custom script.

Additional non-script-based checks (e.g., `checkov`,
`tfsec`, OPA/Rego policy checks) MAY be added to the
pipeline and are encouraged but not constitutionally
mandated.

### Prohibited Gate Implementations

- Quality gates MUST NOT be implemented as Bash, PowerShell,
  or Python wrapper scripts. They MUST be invoked as direct
  tool commands by the CI system or a Makefile/Taskfile with
  transparent, auditable command lines.
- `null_resource` or `local-exec` MUST NOT be used to
  implement any validation or gate logic.

### Definition of Done / Acceptance Criteria

A change to this pattern is considered **conformant** and ready
for merge/deployment when ALL of the following conditions are
met:

1. All five mandatory quality gates (fmt, validate, plan,
   terraform-docs freshness, lint) pass with zero errors.
2. Every Azure resource is provisioned via an AVM module, or a
   documented exception with a tracking issue exists.
3. No `null_resource`, `local-exec`, `remote-exec`,
   provisioner, or external script exists in the codebase.
4. All input variables have type constraints, descriptions,
   and secure defaults. No variable uses type `any`.
5. All outputs have descriptions and expose the IDs/attributes
   required by documented consumer contracts.
6. Diagnostic settings are enabled for every resource that
   supports them; logs route to Log Analytics.
7. No resource exposes a public endpoint unless an explicit
   opt-in variable is set and documented.
8. Zone-redundancy defaults are applied where the resource
   supports them.
9. `terraform plan` with unchanged inputs produces zero
   changes (idempotency verified).
10. `terraform-docs`-generated README sections are current and
    match the codebase.
11. The PR description references the constitutional principles
    addressed and any exceptions granted.

## Governance

This constitution supersedes all other project guidance,
conventions, or informal practices. In any conflict, the
constitution prevails.

- **Amendment process:** Any change to this constitution MUST
  be proposed via a pull request, reviewed by at least one
  maintainer, and approved before merge. The PR MUST include
  a rationale and an impact assessment on existing deployments.
- **Versioning:** The constitution follows Semantic Versioning:
  - **MAJOR** — Backward-incompatible principle removal or
    redefinition.
  - **MINOR** — New principle or materially expanded guidance.
  - **PATCH** — Clarifications, wording, or typo fixes.
- **Compliance review:** Every pull request to this repository
  MUST include a self-assessment checklist confirming
  compliance with each NON-NEGOTIABLE principle. Reviewers
  MUST verify the checklist before approving.
- **Exception process:** Exceptions to any NON-NEGOTIABLE
  principle MUST be documented in an Architecture Decision
  Record (ADR) in `docs/decisions/`, approved by at least two
  maintainers, and tracked as technical debt with a
  remediation timeline.
- **Periodic review:** The constitution SHOULD be reviewed at
  least once per quarter to incorporate AVM updates, new Azure
  capabilities, and lessons learned.

**Version**: 1.0.0 | **Ratified**: 2026-03-05 | **Last Amended**: 2026-03-05
