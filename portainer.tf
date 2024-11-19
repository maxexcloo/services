data "http" "portainer_endpoints" {
  url = "${var.terraform.portainer.url}/endpoints"

  request_headers = {
    X-API-Key = var.terraform.portainer.api_key
  }
}

resource "restapi_object" "portainer_stack" {
  for_each = local.merged_portainer_stacks

  create_path  = "/stacks/create/standalone/repository"
  path         = "/stacks"
  provider     = restapi.portainer
  update_path  = "/stacks/{id}/git/redeploy"
  query_string = "endpointId=${each.value.server_id}"

  data = nonsensitive(jsonencode({
    ComposeFile              = "docker/${each.value.service}.yaml"
    Name                     = each.value.service
    RepositoryAuthentication = true
    RepositoryPassword       = var.terraform.portainer.github_token
    RepositoryURL            = data.github_repository.default.html_url
    RepositoryUsername       = data.github_user.default.username

    AutoUpdate = {
      Interval = "5m"
    }

    Env = [
      for k, v in merge(
        {
          SERVER_DOMAIN_ROOT   = var.default.domain_root
          SERVER_EMAIL         = var.default.email
          SERVER_FQDN_EXTERNAL = var.servers[each.value.server].fqdn_external
          SERVER_FQDN_INTERNAL = var.servers[each.value.server].fqdn_internal
          SERVER_HOST          = each.value.server
          SERVER_TIMEZONE      = var.default.timezone
        },
        each.value.server_enable_b2 ? sensitive({
          SERVER_B2_BUCKET_APPLICATION_KEY    = var.servers[each.value.server].b2.application_key
          SERVER_B2_BUCKET_APPLICATION_KEY_ID = var.servers[each.value.server].b2.application_key_id
          SERVER_B2_BUCKET_BUCKET_NAME        = var.servers[each.value.server].b2.bucket_name
          SERVER_B2_BUCKET_ENDPOINT           = var.servers[each.value.server].b2.endpoint
        }) : {},
        each.value.server_enable_resend ? sensitive({
          SERVER_RESEND_API_KEY = var.servers[each.value.server].resend_api_key
        }) : {},
        each.value.server_enable_secret_hash ? sensitive({
          SERVER_SECRET_HASH = var.servers[each.value.server].secret_hash
        }) : {},
        merge([
          for k, v in try(local.output_config[each.value.name], {}) : sensitive({
            "SERVICE_CONFIG_${index(keys(local.output_config[each.value.name]), k)}_CONTENT" = base64gzip(v)
            "SERVICE_CONFIG_${index(keys(local.output_config[each.value.name]), k)}_PATH"    = k
          })
        ]...),
        each.value.enable_b2 ? sensitive({
          SERVICE_B2_BUCKET_APPLICATION_KEY    = local.output_b2[each.value.name].application_key
          SERVICE_B2_BUCKET_APPLICATION_KEY_ID = local.output_b2[each.value.name].application_key_id
          SERVICE_B2_BUCKET_BUCKET_NAME        = local.output_b2[each.value.name].bucket_name
          SERVICE_B2_BUCKET_ENDPOINT           = local.output_b2[each.value.name].endpoint
        }) : {},
        each.value.enable_database_password ? sensitive({
          SERVICE_DATABASE_PASSWORD = local.output_database_passwords[each.value.name]
        }) : {},
        each.value.fqdn != null ? {
          SERVICE_FQDN = each.value.fqdn
        } : {},
        each.value.enable_resend ? sensitive({
          SERVICE_RESEND_API_KEY = local.output_resend_api_keys[each.value.name]
        }) : {},
        each.value.enable_secret_hash ? sensitive({
          SERVICE_SECRET_HASH = local.output_secret_hashes[each.value.name]
        }) : {},
        each.value.enable_tailscale ? sensitive({
          SERVICE_TAILSCALE_TAILNET_KEY = local.output_tailscale_tailnet_keys[each.value.name]
        }) : {},
        each.value.url != null ? {
          SERVICE_URL = each.value.url
        } : {},
        each.value.enable_dns ? {
          SERVICE_ZONE = each.value.dns_zone != var.default.domain_internal ? "external" : "internal"
        } : {}
      ) : { name = k, value = v }
    ]
  }))
}
