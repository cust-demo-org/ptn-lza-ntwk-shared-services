module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

module "pattern" {
  source = "../.."

  location                              = var.location
  tags                                  = var.tags
  use_random_suffix                     = var.use_random_suffix
  lock                                  = var.lock
  resource_groups                       = var.resource_groups
  log_analytics_workspace_id            = var.log_analytics_workspace_id
  log_analytics_workspace_configuration = var.log_analytics_workspace_configuration
  network_security_groups               = var.network_security_groups
  route_tables                          = var.route_tables
  virtual_networks                      = var.virtual_networks
  private_dns_zone_links                = var.private_dns_zone_links
  managed_identities                    = var.managed_identities
  key_vaults                            = var.key_vaults
  role_assignments                      = var.role_assignments
  vhub_connectivity_definitions         = var.vhub_connectivity_definitions
  bastion_configuration                 = var.bastion_configuration
  flowlog_configuration                 = var.flowlog_configuration
}
