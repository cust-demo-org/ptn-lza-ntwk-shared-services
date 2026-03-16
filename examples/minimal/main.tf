module "pattern" {
  source = "../.."

  location                              = var.location
  tags                                  = var.tags
  lock                                  = var.lock
  resource_groups                       = var.resource_groups
  byo_log_analytics_workspace           = var.byo_log_analytics_workspace
  log_analytics_workspace_configuration = var.log_analytics_workspace_configuration
  network_security_groups               = var.network_security_groups
  route_tables                          = var.route_tables
  virtual_networks                      = var.virtual_networks
  private_dns_zones                     = var.private_dns_zones
  byo_private_dns_zone_links            = var.byo_private_dns_zone_links
  managed_identities                    = var.managed_identities
  key_vaults                            = var.key_vaults
  role_assignments                      = var.role_assignments
  vhub_connectivity_definitions         = var.vhub_connectivity_definitions
  bastion_hosts                         = var.bastion_hosts
  flowlog_configuration                 = var.flowlog_configuration
}
