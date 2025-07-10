locals {
  # Pre-compute expensive JSON parsing
  portainer_endpoints_data = jsondecode(data.http.portainer_endpoints.response_body)

  # Single pass filtering with computed platform for efficiency
  service_filters = {
    for k, service in local.merged_services : k => {
      enable_b2           = service.enable_b2
      enable_dns          = service.enable_dns
      enable_onepassword  = service.enable_database_password || service.enable_password || service.enable_b2 || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.password != "" || service.username != null
      enable_sftpgo       = service.enable_sftpgo
      is_fly_platform     = service.platform == "fly"
      service_data        = service
    }
  }

  # Efficient filtered collections using pre-computed filters
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

  filtered_services_enable_sftpgo = {
    for k, filter in local.service_filters : k => filter.service_data
    if filter.enable_sftpgo
  }

  filtered_services_fly = {
    for k, filter in local.service_filters : k => filter.service_data
    if filter.is_fly_platform
  }
}