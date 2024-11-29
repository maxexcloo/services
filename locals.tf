locals {
  filtered_portainer_endpoints = {
    for k, endpoint in jsondecode(data.http.portainer_endpoints.response_body) : endpoint["Name"] => endpoint
  }

  filtered_portainer_stacks = merge(
    [
      for k, service in local.output_services : (
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
        description              = ""
        dns_content              = try(service.dns_content, can(service.server) ? try(service.dns_zone, "") != var.default.domain_internal ? var.servers[service.server].fqdn_external : var.servers[service.server].fqdn_internal : null)
        dns_zone                 = try(service.dns_zone, can(service.server) ? var.default.domain_internal : null)
        enable_b2                = false
        enable_database_password = false
        enable_dns               = can(service.dns_name) && can(service.dns_zone)
        enable_password          = false
        enable_resend            = false
        enable_secret_hash       = false
        enable_ssl               = true
        enable_ssl_validation    = true
        enable_tailscale         = false
        fqdn                     = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : var.servers[service.server].fqdn_internal : null
        group                    = "Services (${try(service.dns_zone, can(service.port) && can(service.server) ? var.default.domain_internal : "Uncategorized")})"
        icon                     = "homepage"
        name                     = k
        platform                 = "docker"
        server                   = null
        server_cloudflare_tunnel = try(var.servers[service.server].cloudflare_tunnel, null)
        server_flags             = try(var.servers[service.server].flags, [])
        service                  = null
        title                    = title(replace(replace(k, "${try(service.platform, "docker")}-", ""), "-", " "))
        url                      = can(service.dns_name) && can(service.dns_zone) || can(service.port) && can(service.server) ? "${try(service.enable_ssl, true) ? "https://" : "http://"}${can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : var.servers[service.server].fqdn_internal}${can(service.port) ? ":${service.port}" : ""}" : null
        username                 = null
        widget                   = null
        zone                     = try(service.dns_zone, can(service.server) ? var.default.domain_internal : null) == var.default.domain_internal ? "internal" : "external"
      },
      service
    )
  }

  merged_services_configs = merge(
    {
      for k, service in local.merged_services : k => {
        "/app/config/bookmarks.yaml"  = ""
        "/app/config/docker.yaml"     = ""
        "/app/config/kubernetes.yaml" = ""
        "/app/config/settings.yaml"   = templatefile("templates/${service.service}/settings.yaml.tftpl", { default = var.default, homepage = service })
        "/app/config/widgets.yaml"    = templatefile("templates/${service.service}/widgets.yaml.tftpl", { default = var.default, homepage = service })

        "/app/config/services.yaml" = templatefile("templates/${service.service}/services.yaml.tftpl", {
          services = merge(
            {
              for k, server in var.servers : "${contains(server.flags, "docker") ? "" : "​"}${k} (${server.title})" => merge(
                contains(server.flags, "docker") || contains(server.flags, "haos") ? {
                  "CPU" = {
                    href = contains(server.flags, "docker") ? "https://glances.${server.fqdn_internal}" : "https://${server.fqdn_internal}:61208"
                    widget = {
                      metric  = "cpu"
                      type    = "glances"
                      url     = contains(server.flags, "docker") ? "https://glances.${server.fqdn_internal}" : "https://${server.fqdn_internal}:61208"
                      version = contains(server.flags, "docker") ? 4 : 3
                    }
                  }
                } : {},
                contains(server.flags, "docker") || contains(server.flags, "haos") ? {
                  "Memory" = {
                    href = contains(server.flags, "docker") ? "https://glances.${server.fqdn_internal}" : "https://${server.fqdn_internal}:61208"
                    widget = {
                      metric  = "memory"
                      type    = "glances"
                      url     = contains(server.flags, "docker") ? "https://glances.${server.fqdn_internal}" : "https://${server.fqdn_internal}:61208"
                      version = contains(server.flags, "docker") ? 4 : 3
                    }
                  }
                } : {},
                contains(server.flags, "docker") && contains(keys(local.filtered_portainer_endpoints), k) ? {
                  "Portainer" = {
                    href = "${var.terraform.portainer.url}/#!/${local.filtered_portainer_endpoints[k]["Id"]}/docker/dashboard"
                    icon = "portainer"
                    widget = {
                      env  = local.filtered_portainer_endpoints[k]["Id"]
                      key  = var.terraform.portainer.api_key
                      type = "portainer"
                      url  = var.terraform.portainer.url
                    }
                  }
                } : {},
                contains(server.flags, "docker") ? {
                  "Watchtower" = {
                    icon = "watchtower"
                    widget = {
                      key  = server.secret_hash
                      type = "watchtower"
                      url  = "https://watchtower.${server.fqdn_internal}"
                    }
                  }
                } : {},
                contains(server.flags, "docker") && !contains(server.flags, "cloudflare_proxy") ? {
                  "​Speedtest (External)" = {
                    href        = "https://speedtest.${server.fqdn_external}/"
                    icon        = "openspeedtest"
                    siteMonitor = "https://speedtest.${server.fqdn_external}/"
                  }
                } : {},
                contains(server.flags, "docker") ? {
                  "​Speedtest${!contains(server.flags, "cloudflare_proxy") ? " (Internal)" : ""}" = {
                    href        = "https://speedtest.${server.fqdn_internal}/"
                    icon        = "openspeedtest"
                    siteMonitor = "https://speedtest.${server.fqdn_internal}/"
                  }
                } : {},
                {
                  for service in local.output_services : "​${service.title}" => {
                    href        = service.url
                    icon        = service.icon
                    siteMonitor = service.url
                    widget      = jsondecode(templatestring(jsonencode(service.widget), { default = var.default, service = service }))
                  }
                  if service.fqdn != null && service.server == k
                },
                {
                  for service in server.services : "​${service.title}" => {
                    href        = service.url
                    icon        = service.icon
                    siteMonitor = service.url
                    widget      = jsondecode(templatestring(jsonencode(service.widget), { default = var.default, service = service }))
                  }
                }
              )
              if contains(server.flags, "homepage")
            },
            {
              "​Cloud" = {
                for service in local.merged_services : "​${service.title}" => {
                  href        = service.url
                  icon        = service.icon
                  siteMonitor = service.url
                  widget      = jsondecode(templatestring(jsonencode(service.widget), { default = var.default, service = service }))
                }
                if service.platform == "cloud" || service.fqdn != null && service.server == null
              }
            }
          )
        })
      }
      if service.service == "homepage"
    }
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
    for k, random_password in random_password.database_service : k => random_password.result
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => jsondecode(restapi_object.create_response).token
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash_service : k => random_password.result
  }

  output_services = {
    for k, service in local.merged_services : k => merge(
      {
        b2                    = service.enable_b2 ? local.output_b2[service.name] : null
        database_password     = service.enable_database_password ? local.output_database_passwords[service.name] : null
        password              = service.enable_password ? onepassword_item.service[service.name].password : null
        resend_api_key        = service.enable_resend ? local.output_resend_api_keys[service.name] : null
        secret_hash           = service.enable_secret_hash ? local.output_secret_hashes[service.name] : null
        tailscale_tailnet_key = service.enable_tailscale ? local.output_tailscale_tailnet_keys[service.name] : null
      },
      service
    )
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => tailscale_tailnet_key.key
  }
}
