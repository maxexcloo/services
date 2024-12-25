locals {
  filtered_onepassword_services = {
    for k, service in local.filtered_services_all : k => service
    if service.database_name != null || service.database_username != null || service.enable_password || service.enable_b2 || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.username != null
  }

  filtered_portainer_endpoints = {
    for k, endpoint in jsondecode(data.http.portainer_endpoints.response_body) : endpoint["Name"] => endpoint
    if !strcontains(endpoint["Name"], "-disabled")
  }

  filtered_services_all = merge(
    [
      for service_name, service in local.merged_services : (
        service.platform == "docker" && service.server == null ? {
          for server_name, server in var.servers : "${service_name}-${server_name}" => merge(
            service,
            {
              server = server_name
            }
          )
          if contains(server.flags, "docker")
        }
        : {
          (service_name) = service
        }
      )
    ]...
  )

  filtered_services_enable_b2 = {
    for k, service in local.filtered_services_all : k => service
    if service.enable_b2
  }

  filtered_services_enable_dns = {
    for k, service in local.filtered_services_all : k => service
    if service.enable_dns
  }

  filtered_services_fly = {
    for k, service in local.filtered_services_all : k => service
    if service.platform == "fly"
  }

  merged_services = {
    for k, service in var.services : k => merge(
      var.default.service_config,
      {
        dns_content             = can(service.server) ? try(service.dns_zone, "") != var.default.domain_internal ? var.servers[service.server].fqdn_external : var.servers[service.server].fqdn_internal : null
        dns_zone                = can(service.server) ? var.default.domain_internal : null
        enable_cloudflare_proxy = contains(try(var.servers[service.server].flags, []), "cloudflare_proxy") && try(service.dns_zone, can(service.server) ? var.default.domain_internal : null) != var.default.domain_internal
        enable_dns              = can(service.dns_name) && can(service.dns_zone)
        fqdn                    = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : var.servers[service.server].fqdn_internal : null
        group                   = "Services (${try(service.dns_zone, can(service.port) && can(service.server) ? var.default.domain_internal : "Uncategorized")})"
        name                    = replace(k, "/^[^-]*-/", "")
        platform                = element(split("-", k), 0)
        server_flags            = try(var.servers[service.server].flags, [])
        url                     = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? "${try(service.enable_ssl, true) ? "https://" : "http://"}${can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : var.servers[service.server].fqdn_internal}${can(service.port) ? ":${service.port}" : ""}" : null
        zone                    = try(service.dns_zone, can(service.server) ? var.default.domain_internal : null) == var.default.domain_internal ? "internal" : "external"
      },
      service,
      {
        widgets = [
          for widget in try(service.widgets, []) : merge(
            var.default.widget_config,
            {
              description       = try(service.description, var.default.widget_config.description)
              enable_monitoring = try(service.enable_monitoring, var.default.widget_config.enable_monitoring)
              icon              = try(service.service, var.default.widget_config.icon)
              title             = try(service.title, var.default.widget_config.title)
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

  output_config_homepage_services = merge(
    {
      for k, server in var.servers : "1 - ${k} (${server.title})" => merge([
        for service in concat(values(local.output_services_all), server.services) : {
          for widget in service.widgets : "${widget.priority ? "1" : can(widget.widget.type) ? "2" : "3"} - ${templatestring(widget.title, { default = var.default, server = server, service = service })}" => {
            description = widget.description
            href        = widget.enable_href ? templatestring(coalesce(widget.url, service.url), { default = var.default, server = server, service = service }) : null
            icon        = widget.icon
            siteMonitor = widget.enable_monitoring ? templatestring("${coalesce(widget.url, service.url)}${service.monitoring_path}", { default = var.default, server = server, service = service }) : null
            widget      = jsondecode(templatestring(jsonencode(widget.widget), { default = var.default, server = server, service = service }))
          }
        }
        if service.server == k
      ]...)
      if contains(server.flags, "homepage")
    },
    {
      "2 - Cloud" = merge([
        for service in local.output_services_all : {
          for widget in service.widgets : "${widget.priority ? "1" : can(widget.widget.type) ? "2" : "3"} - ${templatestring(widget.title, { default = var.default, service = service })}${service.platform == "cloud" ? "" : " (${title(service.platform)})"}" => {
            description = widget.description
            href        = widget.enable_href ? templatestring(coalesce(widget.url, service.url), { default = var.default, service = service }) : null
            icon        = widget.icon
            siteMonitor = widget.enable_monitoring ? templatestring("${coalesce(widget.url, service.url)}${service.monitoring_path}", { default = var.default, service = service }) : null
            widget      = jsondecode(templatestring(jsonencode(widget.widget), { default = var.default, service = service }))
          }
        }
        if service.platform == "cloud" && service.server == null || service.server == null
      ]...)
    }
  )

  output_config_prometheus_services = concat(
    [
      for service in local.output_portainer_stacks : service
      if service.enable_metrics
    ],
    flatten([
      for server in var.servers : [
        for service in server.services : service
        if service.enable_metrics
      ]
    ])
  )

  output_databases = {
    for k, service in local.filtered_services_all : k => {
      name     = try(service.database_name, "")
      password = try(random_password.database_password[k].result, "")
      username = try(service.database_username, "")
    }
    if service.database_name != null || service.database_username != null
  }

  output_portainer_stack_configs = merge(
    {
      for k, service in local.filtered_services_all : k => {
        "/app/config.yaml" = templatefile(
          "templates/${service.service}/config.yaml",
          {
            default  = var.default
            gatus    = service
            servers  = var.servers
            services = local.merged_services
            tags     = var.tags
          }
        )
      }
      if service.service == "gatus"
    },
    {
      for k, service in local.filtered_services_all : k => {
        "/app/config/bookmarks.yaml"  = ""
        "/app/config/docker.yaml"     = ""
        "/app/config/kubernetes.yaml" = ""
        "/app/config/settings.yaml"   = templatefile("templates/${service.service}/settings.yaml", { default = var.default, homepage = service, services = local.output_config_homepage_services })
        "/app/config/widgets.yaml"    = templatefile("templates/${service.service}/widgets.yaml", { default = var.default, homepage = service })
        "/app/config/services.yaml"   = templatefile("templates/${service.service}/services.yaml", { services = local.output_config_homepage_services })
      }
      if service.service == "homepage"
    },
    {
      for k, service in local.filtered_services_all : k => {
        "/config/config.yaml" = templatefile("templates/${service.service}/config.yaml", { servers = var.servers, services = local.output_config_prometheus_services })
      }
      if service.service == "prometheus"
    }
  )

  output_portainer_stacks = {
    for k, service in local.output_services_all : k => service
    if service.platform == "docker" && service.portainer_endpoint_id != "" && service.service != null
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => sensitive(jsondecode(restapi_object.create_response).token)
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash : k => random_password.result
  }

  output_services_all = {
    for k, service in local.filtered_services_all : k => merge(
      {
        b2                    = try(local.output_b2[k], {})
        database              = try(local.output_databases[k], {})
        password              = try(onepassword_item.service[k].password, "")
        password_bcrypt       = try(replace(bcrypt_hash.password[k].id, "$", "$$"), "")
        portainer_endpoint_id = try(local.filtered_portainer_endpoints[service.server]["Id"], "")
        resend_api_key        = try(local.output_resend_api_keys[k], "")
        secret_hash           = try(local.output_secret_hashes[k], "")
        secret_hash_bcrypt    = try(replace(bcrypt_hash.secret_hash[k].id, "$", "$$"), "")
        tailscale_tailnet_key = try(local.output_tailscale_tailnet_keys[k], "")
      },
      service
    )
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => tailscale_tailnet_key.key
  }
}
