output "b2" {
  description = "Backblaze B2 storage credentials for each service"
  sensitive   = true
  value       = local.outputs_b2
}

output "databases" {
  description = "Database connection details for each service"
  sensitive   = true
  value       = local.outputs_databases
}

output "resend" {
  description = "Resend email API keys for each service"
  sensitive   = true
  value       = local.outputs_resend_api_keys
}

output "secret_hashes" {
  description = "Bcrypt hashed secrets for authentication"
  sensitive   = true
  value       = local.outputs_secret_hashes
}

output "sftpgo" {
  description = "SFTPGo user credentials and configuration"
  sensitive   = true
  value       = local.outputs_sftpgo
}

output "tailscale_tailnet_keys" {
  description = "Tailscale authentication keys for each service"
  sensitive   = true
  value       = local.outputs_tailscale_tailnet_keys
}
