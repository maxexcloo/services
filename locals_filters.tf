locals {
  # Filter services that need specific configurations
  filtered_onepassword_services = {
    for k, service in local.merged_services : k => service
    if service.enable_database_password || service.enable_password || service.enable_b2 || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.password != "" || service.username != null
  }

  filtered_portainer_endpoints = {
    for k, endpoint in jsondecode(data.http.portainer_endpoints.response_body) : endpoint["Name"] => endpoint
    if !strcontains(endpoint["Name"], "-disabled")
  }

  filtered_services_enable_b2 = {
    for k, service in local.merged_services : k => service
    if service.enable_b2
  }

  filtered_services_enable_dns = {
    for k, service in local.merged_services : k => service
    if service.enable_dns
  }

  filtered_services_enable_sftpgo = {
    for k, service in local.merged_services : k => service
    if service.enable_sftpgo
  }

  filtered_services_fly = {
    for k, service in local.merged_services : k => service
    if service.platform == "fly"
  }
}