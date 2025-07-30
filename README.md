# Services

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-success)](https://img.shields.io/badge/status-active-success)

Convention-based Infrastructure as Code for multi-platform service deployment using OpenTofu.

## Quick Start

Get running in under 5 minutes:

```bash
# Copy configuration template
cp terraform.tfvars.sample terraform.tfvars

# Edit with your credentials
vi terraform.tfvars

# Deploy infrastructure
tofu init && tofu plan && tofu apply
```

## Features

- **Convention-based**: Features auto-detected from service attributes
- **DNS management**: Cloudflare with automatic record creation
- **Email**: Resend API integration
- **Monitoring**: Homepage dashboard and Gatus uptime monitoring
- **Multi-platform**: Docker, Fly.io, Vercel, cloud providers
- **Secret management**: 1Password integration with auto-generated passwords
- **Storage**: Backblaze B2 cloud storage
- **VPN**: Tailscale mesh networking

## Installation

Requirements: OpenTofu/Terraform, provider credentials

```bash
git clone <repository-url>
cd services
cp terraform.tfvars.sample terraform.tfvars
```

## Usage

### Basic Service

```hcl
services = {
  "docker-app" = {
    dns     = ["app.example.com"]
    service = "app"
  }
}
```

### Multi-Server Service  

```hcl
services = {
  "docker-loadbalancer" = {
    server_include_tag = "frontend"  # Deploy only to tagged servers
    service = "nginx"
  }
}
```

### Full-Featured Service

```hcl
services = {
  "docker-webapp" = {
    dns      = ["webapp.example.com"]
    storage  = {}                    # Backblaze B2 storage
    database = {}                    # PostgreSQL database  
    email    = {}                    # Resend email API
    username = "admin"               # 1Password entry
    service  = "webapp"
  }
}
```

## Documentation

- **[Architecture](architecture.md)** - Technical implementation details
- **[CLAUDE.md](CLAUDE.md)** - Development guidelines and standards

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature-name`  
3. Follow [development guidelines](CLAUDE.md)
4. Run: `tofu fmt && tofu validate && tofu plan`
5. Submit pull request

## Platforms

| Platform | Use Case | Example |
|----------|----------|---------|
| `cloud-*` | Generic cloud services | `cloud-backup` |
| `docker-*` | Containers via Portainer | `docker-grafana` |
| `fly-*` | Fly.io applications | `fly-gatus` |
| `vercel-*` | Static sites/functions | `vercel-portfolio` |