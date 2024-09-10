data "restapi_object" "portainer_endpoints" {
  path     = "/endpoints"
  provider = restapi.portainer
}

resource "restapi_object" "portainer_stack" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.platform == "docker"
  }

  create_path   = "/stacks/create/standalone/repository"
  id_attribute  = "Id"
  path          = "/stacks"
  provider      = restapi.portainer
  update_method = "POST"
  update_path   = "/stacks/{id}/git"
  query_string  = "endpointId=${local.filtered_portainer_endpoints[each.value.server].endpoint_id}"

  data = jsonencode({
    AdditionalFiles = [],
    AutoUpdate = {
      ForcePullImage = false,
      ForceUpdate    = false,
      Interval       = "5m",
      Webhook        = ""
    },
    ComposeFile              = "docker/${service.service}.yaml",
    Env                      = [],
    fromAppTemplate          = false,
    name                     = each.value.name,
    RepositoryAuthentication = true,
    RepositoryPassword       = var.provider.portainer.github_token,
    RepositoryReferenceName  = "",
    RepositoryURL            = data.github_repository.default.html_url,
    RepositoryUsername       = data.github_user.default.username,
    TLSSkipVerify            = false
  })
}
