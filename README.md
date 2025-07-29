# Services

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-success)](https://img.shields.io/badge/status-active-success)

OpenTofu configuration for managing personal services across Docker, Fly.io, and cloud providers.

## Commands

```bash
tofu init
tofu fmt && tofu validate
tofu apply
tofu output
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes following the code standards in CLAUDE.md
4. Run `tofu fmt && tofu validate && tofu plan` to verify changes
5. Submit a pull request

## Features

- DNS configuration via Cloudflare
- Email via Resend API
- File transfer via SFTPGo
- Monitoring via Homepage dashboard and Gatus
- Multi-platform deployment (Docker, Fly.io, Vercel, cloud)
- Networking via Tailscale mesh
- Secret management via 1Password
- Storage via Backblaze B2

## Getting Started

1. Copy configuration:
   ```bash
   cp terraform.tfvars.sample terraform.tfvars
   ```

2. Update `terraform.tfvars` with your credentials and settings

3. Initialize and apply:
   ```bash
   tofu init && tofu plan && tofu apply
   ```

## Platforms

- **cloud**: Generic cloud services
- **docker**: Docker containers via Portainer
- **fly**: Fly.io applications
- **vercel**: Static sites and serverless functions

## Service Configuration

```hcl
services = {
  "platform-service-name" = {
    dns_name   = "subdomain"
    dns_zone   = "example.com"
    enable_b2  = true
    enable_dns = true
    service    = "service-name"
  }
}
```

## Structure

```
├── *.tf                     # Resource files
├── data.tf                  # Data sources
├── locals_*.tf              # Locals by function
├── outputs.tf               # Outputs
├── providers.tf             # Provider configurations
├── terraform.tf             # Terraform configuration
├── terraform.tfvars         # Instance values
├── terraform.tfvars.sample  # Configuration template
├── variables.tf             # Variable definitions
└── templates/               # Service templates
    ├── docker/              # Docker templates
    ├── gatus/               # Gatus templates
    ├── homepage/            # Homepage templates
    └── www/                 # Web templates
```

## Troubleshooting

Common issues:
1. **Authentication errors**: Verify credentials in `terraform.tfvars`
2. **DNS delays**: Cloudflare changes may take time to propagate
3. **Naming conflicts**: Check for collisions across services
4. **Service naming**: Use `platform-servicename` pattern
