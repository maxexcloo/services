locals {
  merged_services = {
    for k, service in var.services : service.name => merge(
      {
        enable_b2                = false
        enable_database_password = false
        enable_dns               = try(service.dns_content, "") != "" && try(service.dns_name, "") != "" && try(service.dns_zone, "") != "" ? true : false
        enable_password          = false
        enable_resend            = false
        enable_secret_hash       = false
        enable_ssl               = true
        enable_tailscale         = false
        fqdn                     = "${service.dns_name}.${service.dns_zone}"
        group                    = "Services (${service.dns_zone})"
        service                  = ""
        url                      = "${try(service.enable_ssl, true) ? "https://" : "http://"}${service.dns_name}.${service.dns_zone}${try(service.port, 0) != 0 ? ":${service.port}" : ""}/"
        username                 = null
      },
      service
    )
  }

  merged_tags = {
    for i, tag in var.tags : tag.name => merge(
      {
        tailscale_tag = "tag:${tag.name}"
      },
      tag
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

  output_resend = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => {
      api_key = jsondecode(restapi_object.create_response).token
    }
  }

  output_tailscale = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => {
      tailnet_key = tailscale_tailnet_key.key
    }
  }
}
