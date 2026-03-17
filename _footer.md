## Contributing

### Pattern Module Conventions

This pattern module follows a strict set of conventions to ensure consistency and maintainability:

- **AVM-only composition** — All Azure resources are provisioned through [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/). Do not use raw `azurerm_*` resources directly.
- **Implicit toggle pattern** — Optional features are enabled by setting their configuration variable to a non-null value. Avoid adding standalone `enable_*` boolean variables.
- **Map-based iteration** — Collections use `for_each` over user-defined map keys. Avoid `count` except for single-instance conditional resources.
- **Tag merging** — Every module block merges `var.tags` with per-resource tags: `merge(var.tags, each.value.tags)`.
- **Location defaulting** — Per-resource location falls back to `var.location` via `coalesce(each.value.location, var.location)`.
- **Cross-variable validation** — Use `terraform_data` with `lifecycle.precondition` blocks for validations that reference multiple variables, and `variable` validation blocks for single-variable rules.
- **Naming** — Resources with globally unique name requirements (e.g. Log Analytics workspaces, Bastion hosts) must be named explicitly by the pattern consumer. The pattern module does not generate names internally.

### Adding a New Feature

1. **Create a feature spec** — Run the SpecKit specify workflow (`/speckit.specify`) describing the new capability. This generates a structured specification under `specs/<feature>/spec.md`.

2. **Plan the implementation** — Run `/speckit.plan` to produce `plan.md` with architecture decisions, file structure, and module selections.

3. **Generate tasks** — Run `/speckit.tasks` to break the plan into an ordered, dependency-aware task list in `tasks.md`.

4. **Implement** — Run `/speckit.implement` to execute the tasks. This ensures each task is tracked, validated, and marked complete.

5. **Update documentation** — After implementation, regenerate the README by running:

   ```bash
   terraform-docs markdown document . --output-file README.md
   ```

6. **Quality gates** — Before submitting a PR, verify:

   ```bash
   terraform fmt -check -recursive
   terraform validate
   ```

### About This Repository

This repository was created and is maintained using [GitHub SpecKit](https://github.com/apps/speckit) — an AI-assisted specification-driven development workflow. All feature specifications, implementation plans, task breakdowns, data models, and API contracts live under the `specs/` directory.

**Future feature development should follow the SpecKit workflow** to ensure that design documentation, variable contracts, output contracts, and checklists remain in sync with the codebase. This keeps the `specs/` directory as the authoritative source of truth for what the module does and why, not just how.
