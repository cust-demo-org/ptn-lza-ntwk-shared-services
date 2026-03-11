# Quickstart: Testable Examples

**Feature**: 002-testable-examples

## Implementation Order

### Phase A: Root Module Variable Improvements (prerequisite)

1. **Expand variable types (FR-021)**:
   - Add `role_assignments` to: `resource_groups`, `log_analytics_workspace_configuration`, `network_security_groups`, `managed_identities`, `bastion_configuration`, `virtual_networks` (VNet-level)
   - Add `lock` override to `resource_groups`
   - Update `main.tf` module calls to pass new fields through
   - Run `terraform validate` to confirm no regressions

2. **Improve variable descriptions (FR-020)**:
   - Convert all 17+ variable descriptions to multi-line heredoc format
   - Add AVM module reference and registry URL per variable
   - Document each object field with a short description
   - Run `terraform-docs` to regenerate root README

### Phase B: Create Example Scaffolding

For each example (`minimal/`, `vnet_hub/`, `vwan_hub/`, `full/`):

1. Create `terraform.tf` with exact provider pins
2. Create `variables.tf` with all pattern module variables + defaults
3. Create `main.tf` with:
   - Naming module
   - Inline dependencies (scenario-specific)
   - Pattern module call passing all variables
   - `depends_on` on pattern module referencing inline dependencies (when applicable)
4. Create/update `terraform.tfvars` with scenario overrides
5. Create `_header.md` with example description

### Phase C: Validation & Documentation

1. Run `terraform fmt -write=true` in each example
2. Run `terraform validate` in each example
3. Run `terraform plan` in each example (no flags)
4. Generate `README.md` via terraform-docs in each example
5. Run `terraform-docs` on root module (updated descriptions)

## Development Workflow

```bash
# From repository root
cd examples/minimal

# Validate
terraform init
terraform fmt -check
terraform validate
terraform plan    # Should exit 0 with no -var flags

# Full test (requires Azure)
terraform apply -auto-approve
terraform apply   # Should show 0 changes
terraform destroy -auto-approve
```

## Key Design Rules

1. **Variable pass-through**: `main.tf` passes ALL variables from `variables.tf` to the pattern module call
2. **Inline deps only for external resources**: Pattern module creates its own RGs, VNets, NSGs, etc. via variables. Examples only create resources the pattern does NOT create (hub VNet, vWAN, vHub, DNS zones, etc.)
3. **No placeholder IDs**: When variables reference inline dependency IDs, use computed references via locals, not hardcoded fake IDs
4. **Exact provider pins**: Examples use `= X.Y.Z`, root module keeps `~> X.0`
5. **terraform-docs**: Run `terraform-docs markdown table --output-file README.md --output-mode inject .` in each example
