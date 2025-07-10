locals {
  merged_services_all = merge(
    merge([
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
    ]...),
    {
      for service_name, service in var.services : service_name => merge(
        service,
        {
          name = replace(service_name, "/^[^-]*-/", "")
        }
      )
      if can(service.server) || contains(var.default.cloud_platforms, element(split("-", service_name), 0)) && can(service.server) == false
    },
    merge([
      for service_name, service in var.services : {
        for server_name, server in local.output_servers : "${service_name}-${server_name}" => merge(
          service,
          {
            name   = replace(service_name, "/^[^-]*-/", "")
            server = server_name
          }
        )
        if contains(server.flags, element(split("-", service_name), 0)) && (can(service.filter_exclude_server_flag) == false && can(service.filter_include_server_flag) == false || can(service.filter_exclude_server_flag) && contains(server.flags, try(service.filter_exclude_server_flag, "")) == false || contains(server.flags, try(service.filter_include_server_flag, "")))
      }
      if can(service.server) == false
    ]...)
  )

  merged_services = {
    for k, service in local.merged_services_all : k => merge(
      var.default.service_config,
      {
        dns_content             = can(service.server) ? try(service.dns_zone, var.default.service_config.dns_zone) != var.default.domain_internal ? local.output_servers[service.server].fqdn_external : local.output_servers[service.server].fqdn_internal : var.default.service_config.dns_content
        dns_zone                = can(service.server) ? var.default.domain_internal : var.default.service_config.dns_zone
        enable_cloudflare_proxy = contains(try(local.output_servers[service.server].flags, []), "cloudflare_proxy") && try(service.dns_zone, can(service.server) ? var.default.domain_internal : null) != var.default.domain_internal
        enable_dns              = can(service.dns_name) && can(service.dns_zone)
        fqdn                    = can(service.dns_name) && can(service.dns_zone) || can(service.server) ? can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : "${try(service.port, var.default.service_config.port) == var.default.service_config.port && try(service.server_service, var.default.service_config.server_service) == var.default.service_config.server_service ? "${service.name}." : ""}${local.output_servers[service.server].fqdn_internal}" : var.default.service_config.fqdn
        group                   = try(service.dns_zone, can(service.server) ? var.default.domain_internal : var.default.service_config.group)
        platform                = element(split("-", k), 0)
        server_flags            = try(local.output_servers[service.server].flags, var.default.service_config.server_flags)
        url                     = can(service.dns_name) && can(service.dns_zone) || can(service.server) ? "${try(service.enable_ssl, true) ? "https://" : "http://"}${can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : "${try(service.port, var.default.service_config.port) == var.default.service_config.port && try(service.server_service, var.default.service_config.server_service) == var.default.service_config.server_service ? "${service.name}." : ""}${local.output_servers[service.server].fqdn_internal}"}${try(service.port, var.default.service_config.port) != var.default.service_config.port ? ":${service.port}" : ""}" : var.default.service_config.url
        zone                    = try(service.dns_zone, can(service.server) ? var.default.domain_internal : null) == var.default.domain_internal ? "internal" : var.default.service_config.zone
      },
      service
    )
  }

  merged_services_outputs = {
    for k, service in local.merged_services : k => merge(
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
}