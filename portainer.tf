data "restapi_object" "portainer_endpoints" {
  for_each = var.servers

  path         = "/endpoints"
  provider     = restapi.portainer
  search_key   = "Name"
  search_value = each.key
}

resource "restapi_object" "portainer_stack" {
  for_each = local.filtered_portainer_stacks

  create_path  = "/stacks/create/standalone/repository"
  path         = "/stacks"
  provider     = restapi.portainer
  update_path  = "/stacks/{id}/git/redeploy"
  query_string = "endpointId=${data.restapi_object.portainer_endpoints[each.value.server].id}"

  data = jsonencode({
    ComposeFile              = "docker/${each.value.service}.yaml",
    Name                     = each.key,
    RepositoryAuthentication = true,
    RepositoryPassword       = var.terraform.portainer.github_token,
    RepositoryURL            = data.github_repository.default.html_url,
    RepositoryUsername       = data.github_user.default.username

    AutoUpdate = {
      Interval = "5m"
    },

    Env = [
      for k, v in merge(
        {
          SERVER_DOMAIN_EXTERNAL = var.default.domain_external
          SERVER_DOMAIN_INTERNAL = var.default.domain_internal
          SERVER_DOMAIN_ROOT     = var.default.domain_root
          SERVER_EMAIL           = var.default.email
          SERVER_FQDN_EXTERNAL   = var.servers[each.value.server].fqdn_external
          SERVER_FQDN_INTERNAL   = var.servers[each.value.server].fqdn_internal
          SERVER_HOST            = var.servers[each.value.server].host
          SERVER_TIMEZONE        = var.default.timezone
        },
        each.value.server_enable_b2 ? {
          SERVER_B2_BUCKET_APPLICATION_KEY    = var.servers[each.value.server].b2.application_key
          SERVER_B2_BUCKET_APPLICATION_SECRET = var.servers[each.value.server].b2.application_secret
          SERVER_B2_BUCKET_BUCKET_NAME        = var.servers[each.value.server].b2.bucket_name
          SERVER_B2_BUCKET_ENDPOINT           = var.servers[each.value.server].b2.endpoint
        } : {},
        each.value.server_enable_resend ? {
          SERVER_RESEND_API_KEY = var.servers[each.value.server].resend_api_key
        } : {},
        each.value.server_enable_secret_hash ? {
          SERVER_SECRET_HASH = var.servers[each.value.server].secret_hash
        } : {},
        can(each.value.dns_name) && can(each.value.dns_zone) ? {
          SERVICE_FQDN = each.value.fqdn
          SERVICE_URL  = each.value.url
        } : {},
        each.value.enable_b2 ? {
          SERVICE_B2_BUCKET_APPLICATION_KEY    = local.output_b2[each.key].application_key
          SERVICE_B2_BUCKET_APPLICATION_SECRET = local.output_b2[each.key].application_secret
          SERVICE_B2_BUCKET_BUCKET_NAME        = local.output_b2[each.key].bucket_name
          SERVICE_B2_BUCKET_ENDPOINT           = local.output_b2[each.key].endpoint
        } : {},
        each.value.enable_database ? {
          SERVICE_DATABASE_PASSWORD = local.output_databases[each.key].password
        } : {},
        each.value.enable_resend ? {
          SERVICE_RESEND_API_KEY = local.output_resend[each.key].api_key
        } : {},
        each.value.enable_secret_hash ? {
          SERVICE_SECRET_HASH = local.output_secret_hashes[each.key].secret_hash
        } : {},
        each.value.enable_tailscale ? {
          SERVICE_TAILSCALE_TAILNET_KEY = local.output_tailscale[each.key].tailnet_key
        } : {},
        each.value.envs
      ) : "${k}=${v}"
    ],
  })
}
