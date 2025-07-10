locals {
  filtered_onepassword_services = {
    for k, filter in local.service_filters : k => filter.service_data
    if filter.enable_onepassword
  }

  filtered_portainer_endpoints = {
    for k, endpoint in local.portainer_endpoints_data : endpoint["Name"] => endpoint
    if !strcontains(endpoint["Name"], "-disabled")
  }

  filtered_services_enable_b2 = {
    for k, filter in local.service_filters : k => filter.service_data
    if filter.enable_b2
  }

  filtered_services_enable_dns = {
    for k, filter in local.service_filters : k => filter.service_data
    if filter.enable_dns
  }

  filtered_services_enable_password = {
    for k, service in local.merged_services : k => service
    if service.enable_password
  }

  filtered_services_enable_sftpgo = {
    for k, filter in local.service_filters : k => filter.service_data
    if filter.enable_sftpgo
  }

  filtered_services_fly = {
    for k, filter in local.service_filters : k => filter.service_data
    if filter.is_fly_platform
  }

  portainer_endpoints_data = jsondecode(data.http.portainer_endpoints.response_body)

  service_filters = {
    for k, service in local.merged_services : k => {
      enable_b2          = service.enable_b2
      enable_dns         = service.enable_dns
      enable_onepassword = service.enable_database_password || service.enable_password || service.enable_b2 || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.password != "" || service.username != null
      enable_sftpgo      = service.enable_sftpgo
      is_fly_platform    = service.platform == "fly"
      service_data       = service
    }
  }

  unique_dns_zones = toset([
    for k, service in local.filtered_services_enable_dns : service.dns_zone
  ])
}
