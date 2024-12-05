output "b2" {
  sensitive = true
  value     = local.output_b2
}

output "databases" {
  sensitive = true
  value     = local.output_database_passwords
}

output "resend" {
  sensitive = true
  value     = local.output_resend_api_keys
}

output "services" {
  sensitive = true
  value     = local.merged_services
}

output "secret_hashes" {
  sensitive = true
  value     = local.output_secret_hashes
}

output "tailscale_tailnet_keys" {
  sensitive = true
  value     = local.output_tailscale_tailnet_keys
}

resource "local_file" "fly_gatus" {
  for_each = {
    for k, service in local.filtered_services_all : k => service
    if service.service == "gatus"
  }

  filename = "fly/${replace(each.key, "fly-", "")}/config/config.yaml"

  content = templatefile(
    "templates/${each.value.service}/config.yaml",
    {
      default  = var.default
      gatus    = each.value
      servers  = var.servers
      services = local.merged_services
      tags     = var.tags
    }
  )
}
