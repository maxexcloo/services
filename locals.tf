locals {
  filtered_portainer_endpoints = {
    for k, endpoint in jsondecode(data.http.portainer_endpoints.response_body) : endpoint["Name"] => endpoint
  }

  filtered_services_onepassword = {
    for k, service in local.merged_services : k => service
    if service.enable_password || service.enable_b2 || service.enable_database_password || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.username != null
  }

  merged_homepage_bookmarks = merge(
    {
      for k, server in var.servers : "${server.description} (${upper(server.location)})" => merge(
        contains(server.flags, "docker") ? {
          "OpenSpeedTest (External)" = {
            href = "https://speedtest.${server.fqdn_external}/"
            icon = "openspeedtest"
          }
          "OpenSpeedTest (Internal)" = {
            href = "https://speedtest.${server.fqdn_internal}/"
            icon = "openspeedtest"
          }
        } : {},
        server.service.enable ? {
          (server.service.description) = {
            href = server.service.url
            icon = server.service.icon
          }
        } : {},
        {
          for service in local.merged_services : service.description => {
            href = service.url
            icon = service.icon
          }
          if service.fqdn != null && service.server == k
        }
      )
      if contains(server.flags, "homepage")
    },
    {
      "Cloud" = {
        for service in local.merged_services : service.description => {
          href = service.url
          icon = service.icon
        }
        if service.fqdn != null && service.server == null
      }
    }
  )

  merged_homepage_widgets = {
    for k, server in var.servers : k => merge(
      contains(server.flags, "docker") ? {
        glances = {
          label   = "${server.description} (${upper(server.location)})"
          uptime  = true
          url     = "https://glances.${server.fqdn_internal}"
          version = 4
        }
      } : {}
    )
    if contains(server.flags, "homepage")
  }

  merged_portainer_stacks = merge(
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
          if contains(keys(local.filtered_portainer_endpoints), k)
        }
      )
      if service.platform == "docker" && service.service != null
    ]...
  )

  merged_services = {
    for k, service in var.services : k => merge(
      {
        description               = title(replace(k, "-", " "))
        dns_content               = try(service.dns_content, can(service.server) ? can(service.internal) ? var.servers[service.server].fqdn_internal : var.servers[service.server].fqdn_external : null)
        dns_zone                  = try(service.dns_zone, can(service.server) ? can(service.internal) ? var.default.domain_internal : var.default.domain_external : null)
        enable_b2                 = false
        enable_cloudflare_proxy   = false
        enable_database_password  = false
        enable_dns                = can(service.dns_name) && can(service.dns_zone)
        enable_github_deploy_key  = false
        enable_password           = false
        enable_resend             = false
        enable_secret_hash        = false
        enable_ssl                = true
        enable_tailscale          = false
        fqdn                      = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : can(service.internal) ? var.servers[service.server].fqdn_internal : var.servers[service.server].fqdn_external : null
        github_repo               = null
        group                     = "Services (${try(service.dns_zone, can(service.port) && can(service.server) ? can(service.internal) ? var.default.domain_internal : var.default.domain_external : "Uncategorized")})"
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
    for k, b2_bucket in b2_bucket.service : k => {
      application_key    = b2_application_key.service[k].application_key
      application_key_id = b2_application_key.service[k].application_key_id
      bucket_name        = b2_bucket.bucket_name
      endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
    }
  }

  output_database_passwords = {
    for k, random_password in random_password.database_service : k => random_password.result
  }

  output_github = {
    for k, tls_private_key in tls_private_key.github_deploy_key_service : k => {
      deploy_private_key = tls_private_key.private_key_openssh
      deploy_public_key  = tls_private_key.public_key_openssh
      path               = "config/${k}"
      url                = "git@github.com:${data.github_user.default.username}/${local.merged_services[k].github_repo}.git"
    }
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => jsondecode(restapi_object.create_response).token
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash_service : k => random_password.result
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => tailscale_tailnet_key.key
  }
}
