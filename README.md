# Services

OpenTofu configuration for managing personal services across multiple platforms including Docker, Fly.io, and cloud providers.

## Overview

This project manages infrastructure and services for personal applications with features including:

- **Multi-platform deployment**: Docker containers, Fly.io apps, Vercel, and cloud services
- **Service discovery**: Automated DNS configuration via Cloudflare with smart record type detection
- **Secret management**: Integration with 1Password for secure credential storage
- **Storage**: Backblaze B2 buckets with automated application keys
- **Email**: Resend API integration for transactional emails
- **File Transfer**: SFTPGo user management for secure file access
- **Monitoring**: Homepage dashboard and Gatus health checks
- **Networking**: Tailscale mesh networking for secure communication

## Architecture

### File Structure

```
├── data.tf                  # All data sources
├── locals_*.tf              # All locals
│   ├── locals_config.tf     # Configuration file templates
│   ├── locals_filtered.tf   # Service filtering logic
│   ├── locals_output.tf     # Output value computation
│   └── locals_service.tf    # Service merging and configuration
├── variables.tf             # Variable definitions
├── outputs.tf               # Output definitions
├── providers.tf             # Provider configurations
├── terraform.tf             # Terraform configuration and provider versions
├── *.tf                     # Resource files (alphabetically sorted)
├── terraform.tfvars         # Instance values (see terraform.tfvars.sample)
├── terraform.tfvars.sample  # Example configuration template
└── templates/               # Configuration templates for services
    ├── docker/              # Docker service templates
    ├── gatus/               # Gatus configuration templates
    ├── homepage/            # Homepage configuration templates
    └── www/                 # Web service templates
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
- **fly**: Applications deployed to Fly.io with machine provisioning
- **vercel**: Static sites and serverless functions on Vercel
- **cloud**: Generic cloud services

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

### Platform Examples

**Docker Services** (prefix: `docker-`):
- `docker-homepage` - Personal dashboard
- `docker-grafana` - Monitoring platform
- `docker-miniflux` - RSS feed reader

**Fly.io Services** (prefix: `fly-`):
- `fly-webapp` - Web applications
- `fly-api` - API services

**Configuration Features**:
- **DNS**: Automatic Cloudflare DNS record creation
- **Storage**: Backblaze B2 bucket provisioning
- **Secrets**: 1Password integration for credentials
- **Monitoring**: Homepage dashboard and Gatus health checks
- **Email**: Resend API for transactional emails

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
