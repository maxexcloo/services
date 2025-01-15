locals {
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

  filtered_services_fly = {
    for k, service in local.merged_services : k => service
    if service.platform == "fly"
  }

  filtered_services_prometheus = {
    for k, service in local.merged_services_outputs : k => service
    if service.enable_metrics
  }

  merged_services = {
    for k, service in local.merged_services_all : k => merge(
      var.default.service_config,
      {
        dns_content  = can(service.server) ? try(service.dns_zone, var.default.service_config.dns_zone) != var.default.domain_internal ? local.output_servers[service.server].fqdn_external : local.output_servers[service.server].fqdn_internal : var.default.service_config.dns_content
        dns_zone     = can(service.server) ? var.default.domain_internal : var.default.service_config.dns_zone
        enable_proxy = contains(try(local.output_servers[service.server].flags, []), "cloudflare_proxy") && try(service.dns_zone, can(service.server) ? var.default.domain_internal : null) != var.default.domain_internal
        enable_dns   = can(service.dns_name) && can(service.dns_zone)
        fqdn         = can(service.dns_name) && can(service.dns_zone) || can(service.server) ? can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : "${try(service.port, var.default.service_config.port) == var.default.service_config.port && try(service.server_service, var.default.service_config.server_service) == var.default.service_config.server_service ? "${service.name}." : ""}${local.output_servers[service.server].fqdn_internal}" : var.default.service_config.fqdn
        group        = try(service.dns_zone, can(service.server) ? var.default.domain_internal : var.default.service_config.group)
        platform     = element(split("-", k), 0)
        server_flags = try(local.output_servers[service.server].flags, var.default.service_config.server_flags)
        url          = can(service.dns_name) && can(service.dns_zone) || can(service.server) ? "${try(service.enable_ssl, true) ? "https://" : "http://"}${can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : "${try(service.port, var.default.service_config.port) == var.default.service_config.port && try(service.server_service, var.default.service_config.server_service) == var.default.service_config.server_service ? "${service.name}." : ""}${local.output_servers[service.server].fqdn_internal}"}${try(service.port, var.default.service_config.port) != var.default.service_config.port ? ":${service.port}" : ""}" : var.default.service_config.url
        zone         = try(service.dns_zone, can(service.server) ? var.default.domain_internal : null) == var.default.domain_internal ? "internal" : var.default.service_config.zone
      },
      service
    )
  }

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
        if contains(server.flags, element(split("-", service_name), 0))
      }
      if can(service.server) == false
    ]...)
  )

  merged_services_homepage = merge(
    {
      for k, server in local.output_servers : "1 - ${k} (${server.title})" => merge([
        for service in local.merged_services_outputs : {
          for widget in service.widgets : "${widget.priority ? "1" : can(widget.widget.type) ? "2" : "3"} - ${templatestring(widget.title, { default = var.default, server = server, service = service })}" => jsondecode(templatestring(jsonencode({
            description = widget.description
            href        = widget.enable_href ? widget.url : null
            icon        = widget.icon
            siteMonitor = widget.enable_monitoring ? "${widget.url}${widget.monitoring_path}" : null
            widget      = widget.widget
          }), { default = var.default, server = server, service = service }))
          if contains(server.flags, widget.filter_server_flag) && widget.filter_mode == "include" || contains(server.flags, widget.filter_server_flag) == false && widget.filter_mode == "exclude"
        }
        if service.server == k
      ]...)
      if contains(server.flags, "homepage")
    },
    {
      "2 - Cloud" = merge([
        for service in local.merged_services_outputs : {
          for widget in service.widgets : "${widget.priority ? "1" : can(widget.widget.type) ? "2" : "3"} - ${templatestring(widget.title, { default = var.default, service = service })}${service.platform == "cloud" ? "" : " (${title(service.platform)})"}" => jsondecode(templatestring(jsonencode({
            description = widget.description
            href        = widget.enable_href ? widget.url : null
            icon        = widget.icon
            siteMonitor = widget.enable_monitoring ? "${widget.url}${widget.monitoring_path}" : null
            widget      = widget.widget
          }), { default = var.default, service = service }))
        }
        if contains(var.default.cloud_platforms, service.platform) && service.server == null || service.server == null
      ]...)
    }
  )

  merged_services_outputs = {
    for k, service in local.merged_services : k => merge(
      service,
      {
        b2                    = service.enable_b2 ? local.output_b2[k] : {}
        cloudflare_api_token  = cloudflare_api_token.internal.value
        cloudflare_tunnel     = local.output_servers[service.server].cloudflare_tunnel
        database              = service.enable_database_password ? local.output_databases[k] : {}
        password              = service.enable_password ? onepassword_item.service[k].password : ""
        password_bcrypt       = service.enable_password ? replace(bcrypt_hash.password[k].id, "$", "$$") : ""
        portainer_endpoint_id = try(local.filtered_portainer_endpoints[service.server]["Id"], "")
        secret_hash           = service.enable_secret_hash ? local.output_secret_hashes[k] : ""
        secret_hash_bcrypt    = service.enable_secret_hash ? replace(bcrypt_hash.secret_hash[k].id, "$", "$$") : ""
        tailscale_tailnet_key = service.enable_tailscale ? local.output_tailscale_tailnet_keys[k] : ""
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
              monitoring_path   = try(service.monitoring_path, var.default.service_config.monitoring_path)
              title             = try(service.title, var.default.service_config.title)
              url               = can(service.url) ? service.url : ""
            },
            widget
          )
        ]
      }
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

  output_databases = {
    for k, service in local.merged_services : k => {
      name     = service.service
      password = random_password.database_password[k].result
      username = service.service
    }
    if service.enable_database_password
  }

  output_portainer_stack_configs = merge(
    {
      for k, service in local.merged_services : k => {
        "/app/config.yaml" = templatefile(
          "templates/${service.service}/config.yaml",
          {
            default   = var.default
            gatus     = service
            servers   = local.output_servers
            services  = local.merged_services
            tags      = var.tags
            terraform = var.terraform
          }
        )
      }
      if service.service == "gatus"
    },
    {
      for k, service in local.merged_services : k => {
        "/app/config/bookmarks.yaml"  = ""
        "/app/config/docker.yaml"     = ""
        "/app/config/kubernetes.yaml" = ""
        "/app/config/settings.yaml"   = templatefile("templates/${service.service}/settings.yaml", { default = var.default, homepage = service, services = local.merged_services_homepage })
        "/app/config/widgets.yaml"    = templatefile("templates/${service.service}/widgets.yaml", { default = var.default, homepage = service })
        "/app/config/services.yaml"   = templatefile("templates/${service.service}/services.yaml", { services = local.merged_services_homepage })
      }
      if service.service == "homepage"
    },
    {
      for k, service in local.merged_services : k => {
        "/config/config.yaml" = templatefile("templates/${service.service}/config.yaml", { servers = local.output_servers, services = local.filtered_services_prometheus })
      }
      if service.service == "prometheus"
    }
  )

  output_portainer_stacks = {
    for k, service in local.merged_services_outputs : k => service
    if service.platform == "docker" && service.portainer_endpoint_id != "" && service.service != null
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => sensitive(jsondecode(restapi_object.create_response).token)
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash : k => random_password.result
  }

  output_servers = nonsensitive(jsondecode(data.tfe_outputs.infrastructure.values.servers))

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => tailscale_tailnet_key.key
  }
}
