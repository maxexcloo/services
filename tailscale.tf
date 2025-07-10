resource "tailscale_tailnet_key" "service" {
  for_each = local.filtered_services_tailscale

  description   = "ephemeral-${each.key}"
  ephemeral     = true
  preauthorized = true
  reusable      = true
  tags          = ["tag:ephemeral"]
}
