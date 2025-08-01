locals {
  # COMPLETE KISS MIGRATION - All features migrated to convention-based configuration

  output_servers           = nonsensitive(jsondecode(data.tfe_outputs.infrastructure.values.servers))
  portainer_endpoints_data = jsondecode(data.http.portainer_endpoints.response_body)

  config_outputs = merge(
    {
      for k, service in local.services_merged : k => {
        "/app/config.yaml" = templatefile(
          "templates/gatus/config.yaml",
          {
            default   = var.default
            gatus     = service
            server    = try(local.output_servers[service.server], {})
            servers   = local.output_servers
            service   = service
            services  = local.services_merged_outputs
            tags      = var.tags
            terraform = var.terraform
          }
        )
      }
      if try(service.service, "") == "gatus"
    },
    {
      for k, service in local.services_merged : k => {
        "/app/config/services.yaml" = templatefile(
          "templates/homepage/services.yaml",
          {
            default   = var.default
            server    = try(local.output_servers[service.server], {})
            services  = local.services_merged_outputs
            tags      = var.tags
            terraform = var.terraform
          }
        )
        "/app/config/settings.yaml" = templatefile(
          "templates/homepage/settings.yaml",
          {
            default   = var.default
            homepage  = service
            server    = try(local.output_servers[service.server], {})
            services  = local.services_merged_outputs
            tags      = var.tags
            terraform = var.terraform
          }
        )
      }
      if try(service.service, "") == "homepage"
    },
    {
      for k, service in local.services_merged : k => {
        "/config/finger.json" = templatefile(
          "templates/www/finger.json",
          {
            default   = var.default
            server    = try(local.output_servers[service.server], {})
            service   = service
            tags      = var.tags
            terraform = var.terraform
          }
        )
      }
      if try(service.service, "") == "www"
    }
  )

  onepassword_condition = {
    for k, v in local.services_merged : k => (try(v.enable_database_password, false) || try(v.enable_password, false) || try(v.enable_b2, false) || try(v.enable_resend, false) || try(v.enable_secret_hash, false) || try(v.enable_tailscale, false) || try(v.password, "") != "" || try(v.username, "") != "")
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
    for k, service in local.services_merged : k => {
      name     = service.service
      password = random_password.database_password[k].result
      username = service.service
    }
    if try(service.enable_database_password, false)
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => sensitive(jsondecode(restapi_object.create_response).token)
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash : k => random_password.result
  }

  output_sftpgo = {
    for k, sftpgo_user in sftpgo_user.service : k => {
      home_directory = sftpgo_user.home_dir
      password       = sftpgo_user.password
      username       = sftpgo_user.username
      webdav_url     = var.terraform.sftpgo.webdav_url
    }
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => tailscale_tailnet_key.key
  }

  portainer_endpoints = {
    for k, endpoint in local.portainer_endpoints_data : endpoint["Name"] => endpoint
    if !strcontains(endpoint["Name"], "-disabled")
  }

  services_all = merge(
    local.services_expanded,
    local.services_cross_server,
    local.services_from_servers
  )

  services_by_feature = {
    dns         = { for k, v in local.services_merged : k => v if v.enable_dns }
    database    = { for k, v in local.services_merged : k => v if try(v.enable_database_password, false) }
    b2          = { for k, v in local.services_merged : k => v if v.has_b2 }
    secret_hash = { for k, v in local.services_merged : k => v if v.has_secret_hash }
    resend      = { for k, v in local.services_merged : k => v if v.has_resend }
    sftpgo      = { for k, v in local.services_merged : k => v if v.has_sftpgo }
    tailscale   = { for k, v in local.services_merged : k => v if v.has_tailscale }
    fly         = { for k, v in local.services_merged : k => v if v.platform == "fly" }
    portainer   = { for k, v in local.services_merged : k => v if v.platform == "docker" && try(local.portainer_endpoints[v.server]["Id"], "") != "" && try(v.service, "") != "" }
    onepassword = { for k, v in local.services_merged : k => v if local.onepassword_condition[k] }
    auth        = { for k, v in local.services_merged : k => v if try(v.enable_password, false) } # auth services are only those with explicit enable_password flag
  }

  services_computations = {
    for k, service in local.services_all : k => {
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
      if contains(server.flags, split("-", service_name)[0]) && (
        (!can(service.server_exclude_flag) && !can(service.server_include_flag)) ||
        (can(service.server_exclude_flag) && !contains(server.flags, service.server_exclude_flag)) ||
        (can(service.server_include_flag) && contains(server.flags, service.server_include_flag))
      )
    }
    if !can(service.server)
  ]...)

  services_dns_config = {
    for k, service in local.services_all : k => {
      content = local.services_computations[k].has_server ? (
        local.services_computations[k].has_dns ? (
          join(".", slice(split(".", local.services_computations[k].primary_hostname), 1, length(split(".", local.services_computations[k].primary_hostname)))) != var.default.domains.internal ?
          local.services_computations[k].server_config.fqdn_external :
          local.services_computations[k].server_config.fqdn_internal
          ) : (
          local.services_computations[k].server_config.fqdn_internal
        )
      ) : null
      primary_zone = local.services_computations[k].has_dns ? join(".", slice(split(".", local.services_computations[k].primary_hostname), 1, length(split(".", local.services_computations[k].primary_hostname)))) : null
    }
  }

  services_dns_expanded = merge([
    for k, service in local.services_all : {
      for i, hostname in coalesce(service.dns, []) : "${k}-dns-${i}" => {
        hostname    = hostname
        is_primary  = i == 0
        service_key = k
        subdomain   = split(".", hostname)[0]
        zone        = length(split(".", hostname)) == 2 ? hostname : join(".", slice(split(".", hostname), 1, length(split(".", hostname))))
      }
    } if can(service.dns)
  ]...)

  services_expanded = {
    for k, service in var.services : k => merge(
      {
        # Basic service info
        name     = replace(k, "/^[^-]*-/", "")
        platform = split("-", k)[0]

        # Convention-based feature detection (KISS approach) - preserve existing explicit enables
        has_dns         = can(service.dns) && length(coalesce(service.dns, [])) > 0
        has_auth        = can(service.auth) || can(service.username) || try(service.enable_auth, false) || try(service.enable_password, false)
        has_database    = can(service.database) || try(service.enable_database, false) || try(service.enable_database_password, false)
        has_b2          = can(service.storage) || try(service.enable_b2, false)
        has_secret_hash = can(service.secrets) || try(service.enable_secret_hash, false)
        has_resend      = can(service.email) || try(service.enable_resend, false)
        has_sftpgo      = can(service.files) || try(service.enable_sftpgo, false)
        has_tailscale   = can(service.vpn) || try(service.enable_tailscale, false)
        has_monitoring  = try(service.monitoring, try(service.enable_monitoring, true))
        has_href        = try(service.href, try(service.enable_href, true))

        # Server filtering logic
        server_include_flag = try(service.server_include_flag, "")
        server_exclude_flag = try(service.server_exclude_flag, "")

        # Defaults with KISS principles
        description = try(service.description, "")
        group       = try(service.group, "Uncategorized")
        icon        = try(service.icon, "homepage")
        title       = try(service.title, replace(replace(k, "/^[^-]*-/", ""), "-", " "))
        port        = try(service.port, 443)
        ssl         = try(service.ssl, true)
        zone        = try(service.zone, "external")

        # Service-specific config
        config  = try(service.config, {})
        widgets = try(service.widgets, [])
        fly     = try(service.fly, {})
      },
      service
    )
    if can(service.server) || split("-", k)[0] == "fly" || split("-", k)[0] == "vercel"
  }

  services_fqdn_config = {
    for k, service in local.services_all : k => {
      base_hostname = local.services_computations[k].has_dns ? local.services_computations[k].primary_hostname : (
        local.services_computations[k].has_server ? (
          "${try(service.port, 443) == 443 && try(service.server_service, false) == false ? "${service.name}." : ""}${local.services_computations[k].server_config.fqdn_internal}"
        ) : null
      )
      fqdn = local.services_computations[k].has_dns || local.services_computations[k].has_server ? (
        local.services_computations[k].has_dns ? local.services_computations[k].primary_hostname : (
          "${try(service.port, 443) == 443 && try(service.server_service, false) == false ? "${service.name}." : ""}${local.services_computations[k].server_config.fqdn_internal}"
        )
      ) : null
    }
  }

  services_from_servers = merge([
    for server_name, server in local.output_servers : {
      for svc in server.services : "server-${svc.service}-${server_name}" => merge(
        svc,
        {
          group          = "Servers"
          name           = svc.service
          platform       = "server"
          port           = try(svc.port, 443)
          server         = server_name
          server_service = true
          title          = try(svc.title, svc.service)
          username       = server.user.username
          password       = server.password
        }
      )
    }
  ]...)

  services_mail_section = {
    for k, service in local.services_merged : k => service
    if try(local.output_resend_api_keys[k], try(local.output_servers[service.server].resend_api_key, ""), "") != ""
  }

  services_merged = {
    for k, service in local.services_all : k => merge(
      service,
      {
        # DNS configuration
        dns_content             = local.services_dns_config[k].content
        enable_cloudflare_proxy = contains(try(local.services_computations[k].server_config.flags, []), "cloudflare_proxy") && local.services_dns_config[k].primary_zone != null && local.services_dns_config[k].primary_zone != var.default.domains.internal
        enable_dns              = local.services_computations[k].has_dns

        # FQDN and URL
        fqdn = local.services_fqdn_config[k].fqdn
        url = local.services_computations[k].has_dns || local.services_computations[k].has_server ? (
          "${try(service.ssl, true) ? "https://" : "http://"}${local.services_fqdn_config[k].base_hostname}${try(service.port, 443) != 443 ? ":${service.port}" : ""}"
        ) : null

        # Group assignment
        group = local.services_dns_config[k].primary_zone != null ? local.services_dns_config[k].primary_zone : (local.services_computations[k].has_server ? var.default.domains.internal : try(service.group, "Uncategorized"))

        # Server flags
        server_flags = try(local.services_computations[k].server_config.flags, [])

        # Zone determination
        zone_resolved = local.services_dns_config[k].primary_zone == var.default.domains.internal || (local.services_dns_config[k].primary_zone == null && local.services_computations[k].has_server) ? "internal" : "external"

        # Platform attribute (needed for filtering)
        platform = local.services_computations[k].platform

        # Portainer endpoint ID for resource tracking
        portainer_endpoint_id = try(local.portainer_endpoints[service.server]["Id"], "")

        # Template compatibility attributes
        cloudflare_account_token = try(service.cloudflare_account_token, var.terraform.cloudflare.api_key)
        zone                     = try(service.zone, "external")

        # Ensure has_* attributes are preserved for filtering (convention + explicit enables)
        has_auth        = try(service.has_auth, can(service.auth) || can(service.username) || try(service.enable_auth, false) || try(service.enable_password, false))
        has_database    = try(service.has_database, can(service.database) || try(service.enable_database, false) || try(service.enable_database_password, false))
        has_b2          = try(service.has_b2, can(service.storage) || try(service.enable_b2, false))
        has_secret_hash = try(service.has_secret_hash, can(service.secrets) || try(service.enable_secret_hash, false))
        has_resend      = try(service.has_resend, can(service.email) || try(service.enable_resend, false))
        has_sftpgo      = try(service.has_sftpgo, can(service.files) || try(service.enable_sftpgo, false))
        has_tailscale   = try(service.has_tailscale, can(service.vpn) || try(service.enable_tailscale, false))
        has_monitoring  = try(service.has_monitoring, try(service.monitoring, try(service.enable_monitoring, true)))
        has_href        = try(service.has_href, try(service.href, try(service.enable_href, true)))

        # Template defaults (KISS: provide what templates expect)
        database = try(service.has_database, can(service.database) || try(service.enable_database, false) || try(service.enable_database_password, false)) ? {
          name     = service.service
          username = service.service
          password = "PLACEHOLDER" # Actual password available in local.output_databases
          } : {
          name     = ""
          username = ""
          password = ""
        }
        enable_monitoring = try(service.has_monitoring, try(service.monitoring, try(service.enable_monitoring, true)))
        mail = try(service.has_resend, can(service.email) || try(service.enable_resend, false)) ? {
          host     = var.terraform.resend.smtp_host
          port     = var.terraform.resend.smtp_port
          username = var.terraform.resend.smtp_username
          password = "PLACEHOLDER" # Actual API key available in local.output_resend_api_keys
          } : {
          host     = ""
          port     = 587
          username = ""
          password = ""
        }
        oidc_url    = var.default.oidc.url
        password    = try(service.password, "")
        secret_hash = try(service.has_secret_hash, can(service.secrets) || try(service.enable_secret_hash, false)) ? "PLACEHOLDER" : "" # Actual hash available in local.output_secret_hashes
        title       = try(service.title, replace(replace(k, "/^[^-]*-/", ""), "-", " "))
        username    = try(service.username, "")
      }
    )
  }

  services_merged_outputs = {
    for k, service in local.services_merged : k => merge(
      service,
      {
        # Provide actual generated values instead of placeholders
        b2                    = service.has_b2 ? local.output_b2[k] : {}
        database              = try(service.enable_database_password, false) ? local.output_databases[k] : service.database
        password              = try(service.enable_password, false) ? onepassword_item.service[k].password : service.password
        password_bcrypt       = try(service.enable_password, false) ? replace(bcrypt_hash.password[k].id, "$", "$$") : ""
        secret_hash           = service.has_secret_hash ? local.output_secret_hashes[k] : service.secret_hash
        secret_hash_bcrypt    = service.has_secret_hash ? replace(bcrypt_hash.secret_hash[k].id, "$", "$$") : ""
        sftpgo                = service.has_sftpgo ? local.output_sftpgo[k] : {}
        tailscale_tailnet_key = service.has_tailscale ? local.output_tailscale_tailnet_keys[k] : ""
        mail = {
          host     = var.terraform.resend.smtp_host
          password = try(local.output_resend_api_keys[k], try(local.output_servers[service.server].resend_api_key, ""), "")
          port     = var.terraform.resend.smtp_port
          username = var.terraform.resend.smtp_username
        }
        widgets = [
          for widget in try(service.widgets, []) : merge(
            {
              description       = try(service.description, "")
              enable_href       = try(service.enable_href, true)
              enable_monitoring = try(service.enable_monitoring, true)
              icon              = try(service.icon, "homepage")
              title             = try(service.title, service.name)
              url               = try(service.url, "")
            },
            widget
          )
        ]
      }
    )
  }

  unique_dns_zones = toset([
    for k, dns_record in local.services_dns_expanded : dns_record.zone
  ])
}
