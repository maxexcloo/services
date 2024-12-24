resource "restapi_object" "fly_app_service" {
  for_each = local.filtered_services_fly

  destroy_path = "/apps/${each.value.name}"
  path         = "/apps"
  provider     = restapi.fly
  read_path    = "/apps/${each.value.name}"
  update_path  = "/apps/${each.value.name}"

  data = jsonencode({
    app_name = each.value.name
    org_slug = var.terraform.fly.org
  })
}

resource "restapi_object" "fly_app_machine_service" {
  for_each = local.filtered_services_fly

  destroy_path  = "/apps/${restapi_object.fly_app_service[each.key].api_data.name}/machines/{id}/stop"
  path          = "/apps/${restapi_object.fly_app_service[each.key].api_data.name}/machines"
  provider      = restapi.fly
  update_method = "POST"

  data = jsonencode({
    region = each.value.fly.region
    config = {
      image = each.value.fly.image
      checks = {
        http = {
          interval = "5s"
          method   = "GET"
          path     = "/"
          port     = each.value.fly.port
          timeout  = "5s"
          type     = "http"
        }
      }
      env = merge(
        {
          FLY_PROCESS_GROUP = "app"
          PRIMARY_REGION    = each.value.fly.region
        },
        each.value.enable_resend ? { RESEND_API_KEY = local.output_resend_api_keys[each.key] } : {},
        each.value.enable_tailscale ? { TAILSCALE_TAILNET_KEY = local.output_tailscale_tailnet_keys[each.key] } : {},
      )
      files = [
        for path, content in local.output_portainer_stack_configs[each.key] : {
          guest_path = path
          raw_value  = base64encode(content)
        }
      ]
      guest = {
        cpu_kind  = each.value.fly.cpu_type
        cpus      = each.value.fly.cpus
        memory_mb = each.value.fly.memory
      }
      services = [
        {
          internal_port = each.value.fly.port
          protocol      = "tcp"
          ports = [
            {
              force_https = true
              port        = 80
              handlers = [
                "http"
              ]
            },
            {
              port = 443
              handlers = [
                "tls",
                "http"
              ]
            }
          ]
        }
      ]
    }
  })

  force_new = [
    each.value.fly.region,
    each.value.name
  ]
}
