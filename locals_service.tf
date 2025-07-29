locals {
  services_dns_expanded = merge([
    for k, service in local.services_merged_all : {
      for i, hostname in coalesce(service.dns, []) : "${k}-dns-${i}" => {
        hostname    = hostname
        is_primary  = i == 0
        service_key = k
        subdomain   = split(".", hostname)[0]
        zone        = join(".", slice(split(".", hostname), 1, length(split(".", hostname))))
      }
    } if can(service.dns)
  ]...)

  services_computations = {
    for k, service in local.services_merged_all : k => {
      has_dns          = can(service.dns) && length(coalesce(service.dns, [])) > 0
      has_server       = can(service.server)
      platform         = split("-", k)[0]
      primary_hostname = can(service.dns) && length(coalesce(service.dns, [])) > 0 ? service.dns[0] : null
      server_config    = try(local.output_servers[service.server], {})
    }
  }

  services_cross_server = merge([
    for service_name, service in var.services : {
      for server_name, server in local.output_servers : "${service_name}-${server_name}" => merge(
        service,
        {
          name   = replace(service_name, "/^[^-]*-/", "")
          server = server_name
        }
      )
      if contains(server.flags, local.services_filter_logic[service_name].platform) && (
        (!local.services_filter_logic[service_name].has_exclude_flag && !local.services_filter_logic[service_name].has_include_flag) ||
        (local.services_filter_logic[service_name].has_exclude_flag && !contains(server.flags, local.services_filter_logic[service_name].exclude_flag)) ||
        (local.services_filter_logic[service_name].has_include_flag && contains(server.flags, local.services_filter_logic[service_name].include_flag))
      )
    }
    if can(service.server) == false
  ]...)

  services_dns_config = {
    for k, service in local.services_merged_all : k => {
      content = local.services_computations[k].has_server ? (
        local.services_computations[k].has_dns ? (
          join(".", slice(split(".", local.services_computations[k].primary_hostname), 1, length(split(".", local.services_computations[k].primary_hostname)))) != var.default.domain_internal ?
          local.services_computations[k].server_config.fqdn_external :
          local.services_computations[k].server_config.fqdn_internal
          ) : (
          local.services_computations[k].server_config.fqdn_internal
        )
      ) : null
      primary_zone = local.services_computations[k].has_dns ? join(".", slice(split(".", local.services_computations[k].primary_hostname), 1, length(split(".", local.services_computations[k].primary_hostname)))) : null
    }
  }


  services_filter_logic = {
    for service_name, service in var.services : service_name => {
      exclude_flag     = try(service.filter_exclude_server_flag, "")
      has_exclude_flag = can(service.filter_exclude_server_flag)
      has_include_flag = can(service.filter_include_server_flag)
      include_flag     = try(service.filter_include_server_flag, "")
      platform         = split("-", service_name)[0]
    }
  }

  services_fqdn_config = {
    for k, service in local.services_merged_all : k => {
      base_hostname = local.services_computations[k].has_dns ? local.services_computations[k].primary_hostname : (
        local.services_computations[k].has_server ? (
          "${try(service.port, var.default.service_config.port) == var.default.service_config.port && try(service.server_service, var.default.service_config.server_service) == var.default.service_config.server_service ? "${service.name}." : ""}${local.services_computations[k].server_config.fqdn_internal}"
        ) : null
      )
      fqdn = local.services_computations[k].has_dns || local.services_computations[k].has_server ? (
        local.services_computations[k].has_dns ? local.services_computations[k].primary_hostname : (
          "${try(service.port, var.default.service_config.port) == var.default.service_config.port && try(service.server_service, var.default.service_config.server_service) == var.default.service_config.server_service ? "${service.name}." : ""}${local.services_computations[k].server_config.fqdn_internal}"
        )
      ) : var.default.service_config.fqdn
    }
  }

  services_from_servers = merge([
    for server_name, server in local.output_servers : {
      for service in server.services : "server-${service.service}-${server_name}" => merge(
        {
          group          = "Servers"
          port           = 443
          server_service = true
        },
        service,
        {
          name     = service.service
          password = server.password
          server   = server_name
          username = server.user.username
        }
      )
    }
  ]...)

  services_merged = {
    for k, service in local.services_merged_all : k => merge(
      var.default.service_config,
      {
        dns_content             = local.services_dns_config[k].content
        enable_cloudflare_proxy = contains(try(local.services_computations[k].server_config.flags, []), "cloudflare_proxy") && local.services_dns_config[k].primary_zone != null && local.services_dns_config[k].primary_zone != var.default.domain_internal
        enable_dns              = local.services_computations[k].has_dns
        fqdn                    = local.services_fqdn_config[k].fqdn
        group                   = local.services_dns_config[k].primary_zone != null ? local.services_dns_config[k].primary_zone : (local.services_computations[k].has_server ? var.default.domain_internal : var.default.service_config.group)
        platform                = local.services_computations[k].platform
        server_flags            = try(local.services_computations[k].server_config.flags, var.default.service_config.server_flags)
        url = local.services_computations[k].has_dns || local.services_computations[k].has_server ? (
          "${try(service.enable_ssl, true) ? "https://" : "http://"}${local.services_fqdn_config[k].base_hostname}${try(service.port, var.default.service_config.port) != var.default.service_config.port ? ":${service.port}" : ""}"
        ) : var.default.service_config.url
        zone = local.services_dns_config[k].primary_zone == var.default.domain_internal || (local.services_dns_config[k].primary_zone == null && local.services_computations[k].has_server) ? "internal" : var.default.service_config.zone
      },
      service
    )
  }

  services_merged_all = merge(
    local.services_cross_server,
    local.services_from_servers,
    local.services_with_explicit_config
  )

  services_merged_outputs = {
    for k, service in local.services_merged : k => merge(
      service,
      {
        b2                       = service.enable_b2 ? local.output_b2[k] : {}
        cloudflare_account_token = try(local.output_servers[service.server].cloudflare_account_token, null)
        cloudflare_tunnel        = try(local.output_servers[service.server].cloudflare_tunnel, null)
        database                 = service.enable_database_password ? local.output_databases[k] : {}
        password                 = service.enable_password ? onepassword_item.service[k].password : ""
        password_bcrypt          = service.enable_password ? replace(bcrypt_hash.password[k].id, "$", "$$") : ""
        portainer_endpoint_id    = try(local.filtered_portainer_endpoints[service.server]["Id"], "")
        secret_hash              = service.enable_secret_hash ? local.output_secret_hashes[k] : ""
        secret_hash_bcrypt       = service.enable_secret_hash ? replace(bcrypt_hash.secret_hash[k].id, "$", "$$") : ""
        sftpgo                   = service.enable_sftpgo ? local.output_sftpgo[k] : {}
        tailscale_tailnet_key    = service.enable_tailscale ? local.output_tailscale_tailnet_keys[k] : ""
        mail = {
          host     = var.terraform.resend.smtp_host
          password = try(local.output_resend_api_keys[k], local.output_servers[service.server].resend_api_key, "")
          port     = var.terraform.resend.smtp_port
          username = var.terraform.resend.smtp_username
        }
        widgets = [
          for widget in try(service.widgets, []) : merge(
            var.default.widget_config,
            {
              description       = try(service.description, var.default.service_config.description)
              enable_href       = try(service.enable_href, var.default.service_config.enable_href)
              enable_monitoring = try(service.enable_monitoring, var.default.service_config.enable_monitoring)
              icon              = try(service.icon, var.default.service_config.icon)
              title             = try(service.title, var.default.service_config.title)
              url               = can(service.url) ? service.url : ""
            },
            widget
          )
        ]
      }
    )
  }

  services_with_explicit_config = {
    for service_name, service in var.services : service_name => merge(
      service,
      {
        name = replace(service_name, "/^[^-]*-/", "")
      }
    )
    if can(service.server) || contains(var.default.cloud_platforms, split("-", service_name)[0]) && can(service.server) == false
  }
}
