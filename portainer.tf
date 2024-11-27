data "http" "portainer_endpoints" {
  url = "${var.terraform.portainer.url}/endpoints"

  request_headers = {
    X-API-Key = var.terraform.portainer.api_key
  }
}

resource "restapi_object" "portainer_stack" {
  for_each = local.merged_portainer_stacks

  create_path  = "/stacks/create/standalone/string"
  path         = "/stacks"
  provider     = restapi.portainer
  query_string = "endpointId=${each.value.server_id}"

  data = jsonencode({
    name = each.value.service

    stackfilecontent = templatefile("docker/${each.value.service}.yaml.tftpl", {
      database_passwords     = local.output_database_passwords
      default                = var.default
      init_command           = join("; ", [for k, config in try(local.output_config[each.value.name], {}) : "echo '${base64gzip(config)}' | base64 -d | gunzip > ${k}"])
      resend_api_keys        = local.output_resend_api_keys
      secret_hashes          = local.output_secret_hashes
      servers                = var.servers
      service                = each.value
      tailscale_tailnet_keys = local.output_tailscale_tailnet_keys
    })
  })
}
