resource "restapi_object" "fly_app_machine_service" {
  for_each = local.services_by_feature.fly

  destroy_path              = "${restapi_object.fly_app_service[each.key].update_path}/machines/{id}?force=true"
  ignore_all_server_changes = true
  path                      = "${restapi_object.fly_app_service[each.key].update_path}/machines"
  provider                  = restapi.fly
  update_method             = "POST"

  data = sensitive(jsonencode({
    config = {
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
        each.value.has_resend ? { RESEND_API_KEY = local.output_resend_api_keys[each.key] } : {},
        each.value.has_tailscale ? { TAILSCALE_TAILNET_KEY = local.output_tailscale_tailnet_keys[each.key] } : {},
      )
      files = [
        for path, content in local.config_outputs[each.key] : {
          guest_path = path
          raw_value  = base64encode(content)
        }
      ]
      guest = {
        cpu_kind  = each.value.fly.cpu_type
        cpus      = each.value.fly.cpus
        memory_mb = each.value.fly.memory
      }
      image = each.value.fly.image
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
    region = each.value.fly.region
  }))

  depends_on = [
    restapi_object.fly_app_service,
    terraform_data.fly_app_setup
  ]

  force_new = [
    each.value.fly.region,
    each.value.fqdn,
    each.value.name,
    sha256(jsonencode(local.config_outputs[each.key]))
  ]
}

resource "restapi_object" "fly_app_service" {
  for_each = local.services_by_feature.fly

  destroy_path              = "/apps/${each.value.name}"
  ignore_all_server_changes = true
  path                      = "/apps"
  provider                  = restapi.fly
  read_path                 = "/apps/${each.value.name}"
  update_path               = "/apps/${each.value.name}"

  data = sensitive(jsonencode({
    app_name = each.value.name
    org_slug = var.terraform.fly.org
  }))
}

resource "terraform_data" "fly_app_setup" {
  for_each = local.services_by_feature.fly

  depends_on = [
    restapi_object.fly_app_service
  ]

  triggers_replace = {
    app      = each.value.name
    app_id   = restapi_object.fly_app_service[each.key].id
    hostname = each.value.fqdn
  }

  provisioner "local-exec" {
    command = <<-CMD
      curl -f -s \
        -H "Authorization: Bearer ${var.terraform.fly.api_token}" \
        -H "Content-Type: application/json" \
        -X POST \
        https://api.fly.io/graphql \
        -d @- <<EOF
          {
            "query": "mutation {
              cert: addCertificate(appId: \"${each.value.name}\", hostname: \"${each.value.fqdn}\") {
                certificate { configured }
              }
              ipv4: allocateIpAddress(input: { appId: \"${each.value.name}\", type: shared_v4 }) {
                ipAddress { address }
              }
              ipv6: allocateIpAddress(input: { appId: \"${each.value.name}\", type: v6 }) {
                ipAddress { address }
              }
            }"
          }
        EOF
    CMD
    quiet   = true
  }
}
