# Services

OpenTofu configuration for managing personal services across multiple platforms including Docker, Fly.io, and cloud providers.

## Overview

This project manages infrastructure and services for personal applications with features including:

- **Email**: Resend API integration for transactional emails
- **File Transfer**: SFTPGo user management for secure file access
- **Monitoring**: Homepage dashboard and Gatus health checks
- **Multi-platform deployment**: Docker containers, Fly.io apps, Vercel, and cloud services
- **Networking**: Tailscale mesh networking for secure communication
- **Secret management**: Integration with 1Password for secure credential storage
- **Service discovery**: Automated DNS configuration via Cloudflare with smart record type detection
- **Storage**: Backblaze B2 buckets with automated application keys

## Architecture

### File Structure

```
├── *.tf                     # Resource files (alphabetically sorted)
├── data.tf                  # All data sources
├── locals_*.tf              # All locals
│   ├── locals_config.tf     # Configuration file templates
│   ├── locals_filtered.tf   # Service filtering logic
│   ├── locals_output.tf     # Output value computation
│   └── locals_service.tf    # Service merging and configuration
├── outputs.tf               # Output definitions
├── providers.tf             # Provider configurations
├── terraform.tf             # Terraform configuration and provider versions
├── terraform.tfvars         # Instance values (see terraform.tfvars.sample)
├── terraform.tfvars.sample  # Example configuration template
├── variables.tf             # Variable definitions
└── templates/               # Configuration templates for services
    ├── docker/              # Docker service templates
    ├── gatus/               # Gatus configuration templates
    ├── homepage/            # Homepage configuration templates
    └── www/                 # Web service templates
```

### Platforms

- **cloud**: Generic cloud services
- **docker**: Self-hosted Docker containers managed via Portainer
- **fly**: Applications deployed to Fly.io with machine provisioning
- **vercel**: Static sites and serverless functions on Vercel

### Service Configuration

Services are defined in `terraform.tfvars` with the following structure:

```hcl
services = {
  "platform-service-name" = {
    service       = "service-name"
    dns_name      = "subdomain"
    dns_zone      = "example.com"
    enable_b2     = true
    enable_dns    = true
    # ... other configuration
  }
}
```

## Usage

### Prerequisites

1. OpenTofu >= 1.8
2. Terraform Cloud workspace configured
3. Provider credentials configured in `terraform.tfvars` (see `terraform.tfvars.sample` for example configuration)

### Commands

```bash
# Initialize the workspace
tofu init

# Format, validate, and plan changes (always review before applying)
tofu fmt && tofu validate

# Apply changes
tofu apply

# View outputs
tofu output
```

### Getting Started

1. Copy the sample configuration file:
   ```bash
   cp terraform.tfvars.sample terraform.tfvars
   ```

2. Update `terraform.tfvars` with your actual configuration values:
   - Replace all example values with your real credentials and settings
   - Configure your domains, services, and platform integrations
   - See the sample file for complete examples of all supported configurations

3. Initialize and apply:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

### Adding a New Service

1. Add service configuration to `terraform.tfvars` (reference `terraform.tfvars.sample` for examples):
   ```hcl
   services = {
     "docker-myapp" = {
       description  = "My Application"
       dns_name     = "myapp"
       dns_zone     = "example.com"
       enable_b2    = true
       enable_dns   = true
       service      = "myapp"
     }
   }
   ```

2. Create service docker compose file (e.g., `myapp.yaml`) in `templates/docker/` if needed

3. Add templates in `templates/myapp/` for configuration files

4. Plan and apply changes

## Security

- **Access control**: Tailscale provides secure network access
- **Secret management**: Passwords and API keys generated and stored in 1Password
- **Sensitive variables**: All provider credentials are marked as sensitive
- **State encryption**: Terraform state stored securely in Terraform Cloud

## Monitoring

- **Gatus**: Health monitoring and alerting
- **Homepage**: Centralized dashboard at configured URL
- **Service discovery**: Automatic DNS updates for service availability

## Troubleshooting

### Common Issues

1. **Provider authentication errors**: Verify credentials in `terraform.tfvars` (use `terraform.tfvars.sample` as reference)
2. **DNS propagation delays**: Cloudflare changes may take time to propagate
3. **Resource conflicts**: Check for naming collisions across services
4. **Service naming**: Ensure service keys follow the `platform-servicename` pattern (e.g., `docker-homepage`, `fly-myapp`)

### Validation

Run `tofu fmt && tofu validate && tofu plan` to format, validate configuration syntax, and preview changes before applying.

## Contributing

When modifying this configuration:

1. Always run `tofu fmt && tofu validate && tofu plan` before applying changes
2. Follow the CLAUDE.md code quality rules:
   - Recursive alphabetical sorting of all keys
   - count/for_each at top with blank line after
   - Simple values (single-line strings, numbers, bools, null) before complex values (arrays, multiline strings, objects, maps)
   - No comments - code should be self-explanatory
   - Trailing newlines in all files
3. Test changes in a separate workspace when possible
4. Update documentation for new features or significant changes
5. Follow the existing naming conventions and file organization
