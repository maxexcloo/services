resource "restapi_object" "portainer_stack" {
  for_each = local.output_portainer_stacks

  create_path               = "/stacks/create/standalone/string"
  ignore_all_server_changes = true
  path                      = "/stacks"
  provider                  = restapi.portainer
  query_string              = "endpointId=${each.value.portainer_endpoint_id}"

  data = sensitive(jsonencode({
    name = each.value.name

    stackfilecontent = templatefile("templates/docker/${each.value.service}.yaml", {
      config  = join("; ", [for k, config in try(local.config_outputs[each.key], {}) : "echo '${base64gzip(config)}' | base64 -d | gunzip > ${k}"])
      default = var.default
      server  = local.output_servers[each.value.server]
      service = each.value
    })
  }))

  force_new = [
    each.value.portainer_endpoint_id
  ]
}
