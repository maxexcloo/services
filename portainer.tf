resource "restapi_object" "portainer_stack" {
  for_each = local.services_by_feature.portainer

  create_path               = "/stacks/create/standalone/string"
  ignore_all_server_changes = true
  path                      = "/stacks"
  provider                  = restapi.portainer
  query_string              = "endpointId=${try(local.portainer_endpoints[each.value.server]["Id"], "")}"

  data = sensitive(jsonencode({
    name = each.value.name

    stackfilecontent = templatefile("templates/docker/${each.value.service}.yaml", {
      config = join("; ", [for k, config in try(local.config_outputs[each.key], {}) : "echo '${base64gzip(config)}' | base64 -d | gunzip > ${k}"])
      default = merge(var.default, {
        oidc_url   = var.default.oidc.url
        oidc_name  = var.default.oidc.name
        oidc_title = var.default.oidc.title
      })
      server  = local.output_servers[each.value.server]
      service = local.services_merged_outputs[each.key]
    })
  }))

  force_new = [
    each.value.portainer_endpoint_id
  ]
}
