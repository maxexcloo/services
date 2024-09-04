resource "tailscale_tailnet_key" "service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_tailscale
  }

  description   = "ephemeral-${each.value.name}"
  ephemeral     = true
  preauthorized = true
  reusable      = true
  tags          = [local.merged_tags["ephemeral"].tailscale_tag]
}
