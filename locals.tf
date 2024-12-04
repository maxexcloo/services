locals {
  filtered_onepassword_services = {
    for k, service in local.merged_services_all : k => service
    if service.enable_password || service.enable_b2 || service.enable_database_password || service.enable_resend || service.enable_secret_hash || service.enable_tailscale || service.username != null
  }

  filtered_portainer_endpoints = {
    for k, endpoint in jsondecode(data.http.portainer_endpoints.response_body) : endpoint["Name"] => endpoint
    if !strcontains(endpoint["Name"], "-disabled")
  }

  merged_services = {
    for k, service in var.services : k => merge(
      {
        description              = ""
        dns_content              = try(service.dns_content, can(service.server) ? try(service.dns_zone, "") != var.default.domain_internal ? var.servers[service.server].fqdn_external : var.servers[service.server].fqdn_internal : null)
        dns_zone                 = try(service.dns_zone, can(service.server) ? var.default.domain_internal : null)
        enable_b2                = false
        enable_database_password = false
        enable_dns               = can(service.dns_name) && can(service.dns_zone)
        enable_metrics           = false
        enable_password          = false
        enable_resend            = false
        enable_secret_hash       = false
        enable_ssl               = true
        enable_ssl_validation    = true
        enable_tailscale         = false
        fqdn                     = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : var.servers[service.server].fqdn_internal : null
        group                    = "Services (${try(service.dns_zone, can(service.port) && can(service.server) ? var.default.domain_internal : "Uncategorized")})"
        metrics_path             = "/metrics"
        monitoring_path          = ""
        name                     = k
        platform                 = "docker"
        secrets                  = {}
        server                   = null
        server_flags             = try(var.servers[service.server].flags, [])
        service                  = null
        title                    = title(replace(replace(k, "${try(service.platform, "docker")}-", ""), "-", " "))
        url                      = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? "${try(service.enable_ssl, true) ? "https://" : "http://"}${can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : var.servers[service.server].fqdn_internal}${can(service.port) ? ":${service.port}" : ""}" : null
        username                 = null
        zone                     = try(service.dns_zone, can(service.server) ? var.default.domain_internal : null) == var.default.domain_internal ? "internal" : "external"
      },
      service,
      {
        widgets = [
          for widget in try(service.widgets, []) : merge(
            {
              enable_href       = true
              enable_monitoring = true
              icon              = try(service.service, "homepage")
              priority          = false
              widget            = null
            },
            widget
          )
        ]
      }
    )
  }

  merged_services_all = merge(
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

  output_b2 = {
    for k, b2_bucket in b2_bucket.service : k => {
      application_key    = b2_application_key.service[k].application_key
      application_key_id = b2_application_key.service[k].application_key_id
      bucket_name        = b2_bucket.bucket_name
      endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
    }
  }

  output_database_passwords = {
    for k, random_password in random_password.database_password : k => random_password.result
  }

  output_portainer_stack_configs = merge(
    # {
    #   for k, service in local.merged_services_all : k => {
    #     "/config/config.yaml" = templatefile("templates/${service.service}/config.yaml", {
    #       servers = var.servers
    #       services = local.output_services_all
    #     })
    #   }
    #   if service.service == "grafana"
    # },
    {
      for k, service in local.merged_services_all : k => {
        "/app/config/bookmarks.yaml"  = ""
        "/app/config/docker.yaml"     = ""
        "/app/config/kubernetes.yaml" = ""
        "/app/config/settings.yaml"   = templatefile("templates/${service.service}/settings.yaml", { default = var.default, homepage = service })
        "/app/config/widgets.yaml"    = templatefile("templates/${service.service}/widgets.yaml", { default = var.default, homepage = service })
        "/app/config/services.yaml" = templatefile("templates/${service.service}/services.yaml", {
          services = merge(
            {
              for k, server in var.servers : "${contains(server.flags, "docker") ? "" : "​"}${k} (${server.title})" => merge([
                for service in concat(values(local.output_services_all), server.services) : {
                  for widget in service.widgets : "${widget.priority ? "" : "​"}${try(widget.title, service.title)}" => {
                    description = try(widget.description, service.description)
                    href        = widget.enable_href ? templatestring(try(widget.url, service.url), { default = var.default, server = server, service = service }) : null
                    icon        = try(widget.icon, service.icon)
                    siteMonitor = widget.enable_monitoring ? templatestring("${try(widget.url, service.url)}${try(widget.monitoring_path, service.monitoring_path)}", { default = var.default, server = server, service = service }) : null
                    widget      = jsondecode(templatestring(jsonencode(widget.widget), { default = var.default, server = server, service = service }))
                  }
                }
                if service.server == k
              ]...)
              if contains(server.flags, "homepage")
            },
            {
              "​Cloud" = merge([
                for service in local.output_services_all : {
                  for widget in service.widgets : "${widget.priority ? "" : "​"}${try(widget.title, service.title)}${service.platform == "cloud" ? "" : " (${title(service.platform)})"}" => {
                    description = try(widget.description, service.description)
                    href        = widget.enable_href ? templatestring(try(widget.url, service.url), { default = var.default, service = service }) : null
                    icon        = try(widget.icon, service.icon)
                    siteMonitor = widget.enable_monitoring ? templatestring("${try(widget.url, service.url)}${try(widget.monitoring_path, service.monitoring_path)}", { default = var.default, service = service }) : null
                    widget      = jsondecode(templatestring(jsonencode(widget.widget), { default = var.default, service = service }))
                  }
                }
                if service.platform == "cloud" || service.server == null
              ]...)
            }
          )
        })
      }
      if service.service == "homepage"
    },
    {
      for k, service in local.merged_services_all : k => {
        "/config/config.yaml" = templatefile("templates/${service.service}/config.yaml", {
          servers = var.servers

          services = concat(
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
        })
      }
      if service.service == "prometheus"
    }
  )

  output_portainer_stacks = {
    for k, service in local.output_services_all : k => merge(service, { endpoint_id = local.filtered_portainer_endpoints[service.server]["Id"] })
    if service.platform == "docker" && service.service != null && try(contains(keys(local.filtered_portainer_endpoints), service.server), false)
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => jsondecode(restapi_object.create_response).token
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash : k => random_password.result
  }

  output_services_all = {
    for k, service in local.merged_services_all : k => merge(
      {
        b2                    = try(local.output_b2[k], null)
        database_password     = try(local.output_database_passwords[k], null)
        password              = try(onepassword_item.service[k].password, null)
        password_bcrypt       = try(replace(bcrypt_hash.password[k].id, "$", "$$"), null)
        resend_api_key        = try(local.output_resend_api_keys[k], null)
        secret_hash           = try(local.output_secret_hashes[k], null)
        secret_hash_bcrypt    = try(replace(bcrypt_hash.secret_hash[k].id, "$", "$$"), null)
        tailscale_tailnet_key = try(local.output_tailscale_tailnet_keys[k], null)
      },
      service
    )
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => tailscale_tailnet_key.key
  }
}
