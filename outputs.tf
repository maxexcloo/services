output "b2" {
  sensitive = true
  value     = local.output_b2
}

output "databases" {
  sensitive = true
  value     = local.output_databases
}

output "resend" {
  sensitive = true
  value     = local.output_resend
}

output "secret_hashes" {
  sensitive = true
  value     = local.output_secret_hashes
}

output "tailscale" {
  sensitive = true
  value     = local.output_tailscale
}
