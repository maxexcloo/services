locals {
  filtered_portainer_endpoints = {
    for k, endpoint in jsondecode(data.http.portainer_endpoints.response_body) : endpoint["Name"] => endpoint
  }

  filtered_portainer_stacks = merge(
    [
      for k, service in local.merged_services : (
        service.server != null ? (
          contains(keys(local.filtered_portainer_endpoints), service.server) ? {
            (k) = merge(service, { server_id = local.filtered_portainer_endpoints[service.server]["Id"] })
          }
          :
          {}
        )
        :
        {
          for k, server in var.servers : "${service.name}-${k}" => merge(service, { server = k, server_id = local.filtered_portainer_endpoints[k]["Id"] })
          if contains(keys(local.filtered_portainer_endpoints), k) && (contains(server.flags, "caddy") || contains(server.flags, "caddy") == service.enable_caddy_check)
        }
      )
      if service.platform == "docker" && service.service != null
    ]...
  )

  filtered_services_onepassword = {
    for k, service in local.merged_services : k => service
    if service.enable_password || service.enable_b2 || service.enable_database_password || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.username != null
  }

  merged_services = {
    for k, service in var.services : k => merge(
      {
        description               = title(replace(k, "-", " "))
        dns_content               = can(service.dns_content) ? service.dns_content : can(service.server) ? can(service.internal) ? var.servers[service.server].fqdn_internal : var.servers[service.server].fqdn_external : null
        dns_zone                  = can(service.dns_zone) ? service.dns_zone : can(service.server) ? can(service.internal) ? var.default.domain_internal : var.default.domain_external : null
        enable_b2                 = false
        enable_caddy_check        = false
        enable_database_password  = false
        enable_dns                = can(service.dns_name) && can(service.dns_zone)
        enable_github_deploy_key  = false
        enable_homepage_widget    = false
        enable_password           = false
        enable_resend             = false
        enable_secret_hash        = false
        enable_ssl                = true
        enable_tailscale          = false
        fqdn                      = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : can(service.internal) ? var.servers[service.server].fqdn_internal : var.servers[service.server].fqdn_external : null
        github_repo               = null
        group                     = "Services (${can(service.dns_zone) ? service.dns_zone : can(service.port) && can(service.server) ? can(service.internal) ? var.default.domain_internal : var.default.domain_external : "Uncategorized"})"
        icon                      = "homepage"
        internal                  = false
        name                      = k
        platform                  = "docker"
        server                    = null
        server_enable_b2          = false
        server_enable_resend      = false
        server_enable_secret_hash = false
        service                   = null
        url                       = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? "${try(service.enable_ssl, true) ? "https://" : "http://"}${can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : can(service.internal) ? var.servers[service.server].fqdn_internal : var.servers[service.server].fqdn_external}${can(service.port) ? ":${service.port}" : ""}/" : null
        username                  = null
      },
      service
    )
  }

  output_b2 = {
    for k, service in local.merged_services : k => {
      application_key    = b2_application_key.service[k].application_key_id
      application_secret = b2_application_key.service[k].application_key
      bucket_name        = b2_bucket.service[k].bucket_name
      endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
    }
    if service.enable_b2
  }

  output_databases = {
    for k, service in local.merged_services : k => {
      password = random_password.database_service[k].result
    }
    if service.enable_database_password
  }

  output_github = {
    for k, service in local.merged_services : k => {
      deploy_private_key = tls_private_key.github_deploy_key_service[k].private_key_openssh
      deploy_public_key  = tls_private_key.github_deploy_key_service[k].public_key_openssh
      path               = "config/${k}"
      url                = "git@github.com:${data.github_user.default.username}/${service.github_repo}.git"
    }
    if service.enable_github_deploy_key
  }

  output_resend = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => {
      api_key = jsondecode(restapi_object.create_response).token
    }
  }

  output_secret_hashes = {
    for k, service in local.merged_services : k => {
      secret_hash = random_password.secret_hash_service[k].result
    }
    if service.enable_secret_hash
  }

  output_tailscale = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => {
      tailnet_key = tailscale_tailnet_key.key
    }
  }
}
