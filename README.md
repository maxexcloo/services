# Services

OpenTofu configuration for managing personal services across multiple platforms including Docker, Fly.io, and cloud providers.

## Overview

This project manages infrastructure and services for personal applications with features including:

- **Multi-platform deployment**: Docker containers, Fly.io apps, and cloud services
- **Service discovery**: Automated DNS configuration via Cloudflare
- **Secret management**: Integration with 1Password for secure credential storage
- **Storage**: Backblaze B2 buckets for each service
- **Monitoring**: Homepage dashboard and Gatus health checks
- **Networking**: Tailscale mesh networking for secure communication

## Architecture

### File Structure

```
├── terraform.tf              # Terraform configuration and provider versions
├── providers.tf              # Provider configurations
├── variables.tf              # Variable definitions with types and validation
├── outputs.tf                # Output definitions
├── terraform.tfvars          # Variable values (sensitive)
├── locals_*.tf               # Local value computations split by domain
│   ├── locals_filters.tf     # Service filtering logic
│   ├── locals_services.tf    # Service merging and configuration
│   ├── locals_outputs.tf     # Output value computation
│   └── locals_configs.tf     # Configuration file templates
├── *.tf                      # Individual service configurations
└── templates/                # Configuration templates for services
```

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

### Platforms

- **docker**: Self-hosted Docker containers managed via Portainer
- **fly**: Applications deployed to Fly.io
- **cloud**: Generic cloud services

## Usage

### Prerequisites

1. OpenTofu/Terraform >= 1.0
2. Terraform Cloud workspace configured
3. Provider credentials configured in `terraform.tfvars`

### Commands

```bash
# Initialize the workspace
tofu init

# Plan changes (always review before applying)
tofu plan

# Apply changes
tofu apply

# View outputs
tofu output
```

### Adding a New Service

1. Add service configuration to `terraform.tfvars`:
   ```hcl
   services = {
     "docker-myapp" = {
       service      = "myapp"
       dns_name     = "myapp"
       dns_zone     = "example.com"
       enable_dns   = true
       enable_b2    = true
       description  = "My Application"
     }
   }
   ```

2. Create service-specific resource file (e.g., `myapp.tf`) if needed

3. Add templates in `templates/myapp/` for configuration files

4. Plan and apply changes

### Configuration Templates

Service configurations are generated from templates in the `templates/` directory. Common templates include:

- `config.yaml` - Application configuration
- `settings.yaml` - Service-specific settings
- `docker-compose.yml` - Docker container definitions

## Security

- **Sensitive variables**: All provider credentials are marked as sensitive
- **Secret management**: Passwords and API keys generated and stored in 1Password
- **Access control**: Tailscale provides secure network access
- **State encryption**: Terraform state stored securely in Terraform Cloud

## Monitoring

- **Homepage**: Centralized dashboard at configured URL
- **Gatus**: Health monitoring and alerting
- **Service discovery**: Automatic DNS updates for service availability

## Troubleshooting

### Common Issues

1. **Provider authentication errors**: Verify credentials in `terraform.tfvars`
2. **DNS propagation delays**: Cloudflare changes may take time to propagate
3. **Resource conflicts**: Check for naming collisions across services

### Validation

Run `tofu validate` to check configuration syntax and `tofu plan` to preview changes before applying.

## Contributing

When modifying this configuration:

1. Always run `tofu plan` before applying changes
2. Test changes in a separate workspace when possible
3. Update documentation for new features or significant changes
4. Follow the existing naming conventions and file organization

