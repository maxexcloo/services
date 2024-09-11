locals {
  filtered_portainer_stacks = merge(
    [
      for k, service in local.merged_services : (
        service.server != null ?
        { k = service }
        :
        { for server_name, server in var.servers :
          "${k}_${server_name}" => merge(service, { server = server_name })
        }
      )
      if service.platform == "docker"
    ]...
  )

  merged_services = {
    for k, service in var.services : k => merge(
      {
        description               = ""
        dns_zone                  = ""
        enable_b2                 = false
        enable_database           = false
        enable_dns                = can(service.dns_content) && can(service.dns_name) && can(service.dns_zone)
        enable_password           = false
        enable_resend             = false
        enable_secret_hash        = false
        enable_ssl                = true
        enable_tailscale          = false
        envs                      = {}
        fqdn                      = can(service.dns_name) && can(service.dns_zone) ? "${service.dns_name}.${service.dns_zone}" : null
        group                     = can(service.dns_zone) ? "Services (${service.dns_zone})" : "Services (Uncategorized)"
        platform                  = "docker"
        port                      = 0
        server                    = null
        server_enable_b2          = false
        server_enable_resend      = false
        server_enable_secret_hash = false
        service                   = null
        url                       = can(service.dns_name) && can(service.dns_zone) ? "${try(service.enable_ssl, true) ? "https://" : "http://"}${service.dns_name}.${service.dns_zone}${try(service.port, 0) > 0 ? ":${service.port}" : ""}/" : null
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
      password = random_password.database_sevice[k].result
    }
    if service.enable_database
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
