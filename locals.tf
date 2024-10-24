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
          for k, server in var.servers : "${service.name}-${server.host}" => merge(service, { server = server.host, server_id = local.filtered_portainer_endpoints[server.host]["Id"] })
          if contains(keys(local.filtered_portainer_endpoints), server.host) && (contains(server.flags, "caddy") || contains(server.flags, "caddy") == service.enable_caddy_check)
        }
      )
      if service.platform == "docker" && service.service != null
    ]...
  )

  merged_services = {
    for k, service in var.services : k => merge(
      {
        description               = ""
        dns_zone                  = ""
        enable_b2                 = false
        enable_caddy_check        = false
        enable_database           = false
        enable_dns                = can(service.dns_content) && can(service.dns_name) && can(service.dns_zone)
        enable_github_deploy_key  = false
        enable_homepage_widget    = false
        enable_password           = false
        enable_resend             = false
        enable_secret_hash        = false
        enable_ssl                = true
        enable_tailscale          = false
        envs                      = {}
        fqdn                      = can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : null
        github_path               = "config/${k}"
        github_repo               = null
        github_url                = can(service.github_repo) ? "git@github.com:${data.github_user.default.username}/${service.github_repo}.git" : null
        group                     = can(service.dns_zone) ? "Services (${service.dns_zone})" : "Services (Uncategorized)"
        icon                      = "homepage"
        name                      = k
        platform                  = "docker"
        port                      = 0
        server                    = null
        server_enable_b2          = false
        server_enable_resend      = false
        server_enable_secret_hash = false
        server_id                 = null
        service                   = null
        url                       = can(service.dns_name) && can(service.dns_zone) ? "${try(service.enable_ssl, true) ? "https://" : "http://"}${service.dns_name}.${service.dns_zone}${try(service.port, 0) > 0 ? ":${service.port}" : ""}/" : null
        username                  = null
        widget                    = {}
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
      password = random_password.database_sevice[k].result
    }
    if service.enable_database
  }

  output_github = {
    for k, service in local.merged_services : k => {
      deploy_private_key = tls_private_key.github_deploy_key_service[k].private_key_openssh
      deploy_public_key  = tls_private_key.github_deploy_key_service[k].public_key_openssh
      path               = service.github_path
      url                = service.github_url
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
