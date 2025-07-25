locals {
  filtered_portainer_endpoints = {
    for k, endpoint in local.filtered_portainer_endpoints_data : endpoint["Name"] => endpoint
    if !strcontains(endpoint["Name"], "-disabled")
  }

  filtered_portainer_endpoints_data = jsondecode(data.http.portainer_endpoints.response_body)

  filtered_service_filters = {
    for k, service in local.services_merged : k => {
      enable_b2          = service.enable_b2
      enable_dns         = service.enable_dns
      enable_onepassword = service.enable_database_password || service.enable_password || service.enable_b2 || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.password != "" || service.username != null
      enable_password    = service.enable_password
      enable_secret_hash = service.enable_secret_hash
      enable_sftpgo      = service.enable_sftpgo
      enable_tailscale   = service.enable_tailscale
      is_fly_platform    = service.platform == "fly"
      service_data       = service
    }
  }

  filtered_services_b2 = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.enable_b2
  }

  filtered_services_database_password = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.service_data.enable_database_password
  }

  filtered_services_dns = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.enable_dns
  }

  filtered_services_fly = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.is_fly_platform
  }

  filtered_services_mail_section = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if try(local.output_resend_api_keys[k], local.output_servers[filter.service_data.server].resend_api_key, "") != ""
  }

  filtered_services_onepassword = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.enable_onepassword
  }

  filtered_services_password = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.enable_password
  }

  filtered_services_resend = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.service_data.enable_resend
  }

  filtered_services_secret_hash = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.enable_secret_hash
  }

  filtered_services_sftpgo = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.enable_sftpgo
  }

  filtered_services_tailscale = {
    for k, filter in local.filtered_service_filters : k => filter.service_data
    if filter.enable_tailscale
  }

  filtered_unique_dns_zones = toset([
    for k, service in local.filtered_services_dns : service.dns_zone
  ])
}
