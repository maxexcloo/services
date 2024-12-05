resource "tailscale_tailnet_key" "service" {
  for_each = {
    for k, service in local.filtered_services_all : k => service
    if service.enable_tailscale
  }

  description   = "ephemeral-${each.key}"
  ephemeral     = true
  preauthorized = true
  reusable      = true
  tags          = ["tag:ephemeral"]
}
