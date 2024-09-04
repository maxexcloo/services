output "b2" {
  sensitive = true
  value     = local.output_b2
}

output "resend" {
  sensitive = true
  value     = local.output_resend
}

output "tailscale" {
  sensitive = true
  value     = local.output_tailscale
}
