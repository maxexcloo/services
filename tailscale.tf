resource "tailscale_tailnet_key" "service" {
  for_each = local.services_by_feature.tailscale

  description   = "ephemeral-${each.key}"
  ephemeral     = true
  preauthorized = true
  reusable      = true
  tags          = ["tag:ephemeral"]
}
