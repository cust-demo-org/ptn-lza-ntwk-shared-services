# Description Style Contract

**Feature**: 003-avm-variable-descriptions  
**Date**: 2026-03-17  
**Purpose**: Defines the exact formatting rules for variable descriptions in `variables.tf`. All descriptions MUST conform to this contract.

---

## 1. Top-Level Variable Description Structure

### For `map(object({...}))` variables:

> **Note:** The `<<DESCRIPTION` heredoc marker below is a template placeholder. Implementers MUST use the codebase's actual heredoc marker (e.g., `<<-EOT`) when writing descriptions in `variables.tf`.

```hcl
variable "example" {
  description = <<DESCRIPTION
A map of <resource_plural> to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `field_one` - (Required) Description of field one.
- `field_two` - (Optional) Description of field two. Defaults to `value`.
- `nested_object` - (Optional) A nested object with the following attributes:
  - `sub_field` - (Required) Description of sub-field.
  - `sub_optional` - (Optional) Description. Defaults to `value`.

> Note: any callout text here.
DESCRIPTION
```

### For single `object({...})` variables:

```hcl
variable "example_config" {
  description = <<DESCRIPTION
Configuration for <resource>. The following attributes are supported:

- `field_one` - (Required) Description.
- `field_two` - (Optional) Description. Defaults to `value`.
DESCRIPTION
```

### For simple scalars (FR-018):

```hcl
variable "location" {
  description = "The Azure region where resources will be deployed. Must be a valid Azure location."
```

---

## 2. Attribute Bullet Format

**Template**: `- \`attribute_name\` - (Required|Optional) Description sentence. Defaults to \`value\`.`

### Rules:
1. **Backtick-wrap** the attribute name: `` `attribute_name` ``
2. **Dash separator** after backtick: `` `name` - ``
3. **Marker** immediately after dash: `(Required)` or `(Optional)` — every leaf attribute must have one
4. **Description** starts with uppercase, ends with period
5. **Defaults** stated at end: `Defaults to \`value\`.` or `Defaults to \`null\`.`
6. **Allowed values** listed inline: `Possible values are \`"Value1"\` and \`"Value2"\`.`
7. **No trailing whitespace** after period

### Nesting:
- Top-level attributes: `- \`field\` - ...`
- Second-level (sub-object): `  - \`sub_field\` - ...` (2-space indent)
- Third-level: `    - \`sub_sub_field\` - ...` (4-space indent)

---

## 3. Standard Interface Block Templates

### 3a. `lock` Block

```
- `lock` - (Optional) Controls the Resource Lock configuration for this resource. The following properties can be specified:
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
```

### 3b. `role_assignments` Block (Standard)

```
- `role_assignments` - (Optional) A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
  - `principal_id` - (Required) The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
```

### 3c. `role_assignments` Block (Managed Identity Variant)

```
- `role_assignments` - (Optional) A map of role assignments to create for this managed identity. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `scope` - (Required) The resource ID of the scope to assign the role on.
  - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
```

### 3d. `diagnostic_settings` Block

```
- `diagnostic_settings` - (Optional) A map of diagnostic settings to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
```

### 3e. `private_endpoints` Block

```
- `private_endpoints` - (Optional) A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. [uses standard role_assignments template]
  - `lock` - (Optional) [uses standard lock template]
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - (Required) The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint.
  - `application_security_group_associations` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint.
  - `application_security_group_resource_ids` - (Optional) A set of resource IDs of application security groups to associate with the private endpoint.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `location` - (Optional) The Azure region where the private endpoint will be created. Defaults to the resource's location.
  - `resource_group_resource_id` - (Optional) The resource ID of the resource group to deploy the private endpoint in. Defaults to the resource's resource group.
  - `ip_configurations` - (Optional) A map of IP configurations for the private endpoint:
    - `name` - (Required) The name of the IP configuration.
    - `private_ip_address` - (Required) The private IP address of the IP configuration.
    - `member_name` - (Optional) The member name of the IP configuration.
    - `subresource_name` - (Optional) The subresource name of the IP configuration.
```

### 3f. Standalone `role_assignments` Variable (L821)

**WARNING**: This is the top-level `role_assignments` variable — NOT the nested `role_assignments` block inside other variables. It uses a completely different AVM module (`avm-res-authorization-roleassignment` v0.3.0) and has a different field set.

```
A map of standalone role assignments at arbitrary scopes. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign.
- `scope` - (Required) The Azure resource ID scope for the assignment.
- `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key`.
- `managed_identity_key` - (Optional) The key of a managed identity in the `managed_identities` variable. Mutually exclusive with `principal_id`.
- `description` - (Optional) The description of the role assignment.
- `principal_type` - (Optional) The type of the principal. Possible values are `User`, `Group` and `ServicePrincipal`.

> Note: Specify either `principal_id` or `managed_identity_key`, not both. Use `managed_identity_key` to reference a managed identity created by this pattern.
```

**Key differences from nested `role_assignments` (§3b)**:
- Has `scope` field (nested blocks are scoped to their parent resource)
- Has `managed_identity_key` (pattern cross-reference)
- No `skip_service_principal_aad_check`, `condition`, `condition_version`, `delegated_managed_identity_resource_id`
- Only 6 fields vs 9 fields in §3b

---

## 4. Pattern-Specific Notes

### Cross-Reference Keys

```
- `resource_group_key` - (Required) The key of the resource group in the `resource_groups` variable where this resource will be deployed.
```

Always state which variable the key references. The description must make clear that the key must correspond to an existing entry in the referenced variable (e.g., "The key of the resource group **in the `resource_groups` variable**" implies the key must exist there). If a `validation` block enforces this constraint, mention the constraint per FR-017.

### Pattern Callout Format

After the AVM-sourced attribute list, append pattern-specific notes as:

```
> **Pattern note:** <pattern-specific text>
```

Examples:
- `> **Pattern note:** If not specified, defaults to \`var.location\`.`
- `> **Pattern note:** When \`use_default_log_analytics\` is \`true\`, the \`workspace_resource_id\` is automatically set to the Log Analytics workspace created by this pattern.`

---

## 5. `use_default_log_analytics` Pattern Attribute

This boolean attribute is pattern-specific (not from AVM) and appears in `diagnostic_settings` blocks:

```
  - `use_default_log_analytics` - (Optional) When `true`, automatically sets the `workspace_resource_id` to the Log Analytics workspace created by this pattern. Defaults to `true`.
```

---

## 6. Mutual Exclusivity Documentation (FR-017)

When two attributes are mutually exclusive, document BOTH:

### Inline on each attribute:

```
- `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key`.
- `managed_identity_key` - (Optional) The key of a managed identity in the `managed_identities` variable. Mutually exclusive with `principal_id`.
```

### Callout after the attribute list:

```
> Note: Specify either `principal_id` or `managed_identity_key`, not both. Use `managed_identity_key` to reference a managed identity created by this pattern.
```

---

## 7. terraform-docs Rendering Rules

1. **Use `<<DESCRIPTION` heredoc** — not inline quotes (already the case for complex variables)
2. **No trailing spaces** on any line
3. **Blank line before `> Note:`** callouts
4. **Consistent indentation** — 2 spaces per nesting level
5. **No HTML tags** — pure Markdown
6. **Backticks inside descriptions** — use `\`value\`` for escaped quotes within heredoc, or `` `value` `` for unescaped
7. **Test rendering** — run `terraform-docs .` after every variable rewrite and inspect output
