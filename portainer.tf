data "http" "portainer_endpoints" {
  url = "${var.terraform.portainer.url}/api/endpoints"

  request_headers = {
    X-API-Key = var.terraform.portainer.api_key
  }
}

resource "restapi_object" "portainer_stack" {
  for_each = local.output_portainer_stacks

  create_path  = "/stacks/create/standalone/string"
  path         = "/stacks"
  provider     = restapi.portainer
  query_string = "endpointId=${each.value.portainer_endpoint_id}"

  data = jsonencode({
    name = replace(each.key, "docker-", "")

    stackfilecontent = templatefile("templates/docker/${each.value.service}.yaml", {
      config  = join("; ", [for k, config in try(local.output_portainer_stack_configs[each.key], {}) : "echo '${base64gzip(config)}' | base64 -d | gunzip > ${k}"])
      default = var.default
      server  = var.servers[each.value.server]
      service = each.value
    })
  })
}
