locals {
  filters_portainer_endpoints_data = jsondecode(data.http.portainer_endpoints.response_body)
  filters_unique_dns_zones = toset([
    for k, service in local.filters_services_enable_dns : service.dns_zone
  ])
  filters_portainer_endpoints = {
    for k, endpoint in local.filters_portainer_endpoints_data : endpoint["Name"] => endpoint
    if !strcontains(endpoint["Name"], "-disabled")
  }
  filters_service_filters = {
    for k, service in local.services_merged : k => {
      enable_b2          = service.enable_b2
      enable_dns         = service.enable_dns
      enable_onepassword = service.enable_database_password || service.enable_password || service.enable_b2 || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.password != "" || service.username != null
      enable_sftpgo      = service.enable_sftpgo
      is_fly_platform    = service.platform == "fly"
      service_data       = service
    }
  }
  filters_services_enable_b2 = {
    for k, filter in local.filters_service_filters : k => filter.service_data
    if filter.enable_b2
  }

  filters_services_enable_dns = {
    for k, filter in local.filters_service_filters : k => filter.service_data
    if filter.enable_dns
  }

  filters_services_enable_password = {
    for k, service in local.services_merged : k => service
    if service.enable_password
  }

  filters_services_enable_sftpgo = {
    for k, filter in local.filters_service_filters : k => filter.service_data
    if filter.enable_sftpgo
  }

  filters_services_fly = {
    for k, filter in local.filters_service_filters : k => filter.service_data
    if filter.is_fly_platform
  }

  filters_services_onepassword = {
    for k, filter in local.filters_service_filters : k => filter.service_data
    if filter.enable_onepassword
  }
}
