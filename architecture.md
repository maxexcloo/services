# Architecture

## Overview

Convention-based Infrastructure as Code system for multi-platform service deployment using OpenTofu/Terraform.

## Core Principles

- **Convention over Configuration**: Features auto-detected from service attributes
- **Declarative**: Services defined in HCL, infrastructure managed automatically
- **KISS**: Simple, readable code over clever abstractions
- **Multi-Platform**: Deploy to Docker, Fly.io, Vercel, and cloud providers

## Architecture Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   terraform     │    │   var.services  │    │   var.default   │
│   .tfvars       │────▶│   (HCL config)  │    │   (global cfg)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        │
                    ┌─────────────────┐                │
                    │ Service         │                │
                    │ Expansion       │◀───────────────┘
                    │ Logic           │
                    └─────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Feature Detection                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐│
│  │ DNS         │ │ Storage     │ │ Database    │ │ Auth        ││
│  │ dns: [...]  │ │ storage: {} │ │ database:{} │ │ username    ││  
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Resource Generation                           │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │ Cloudflare  │ │ Portainer   │ │ 1Password   │ │ Backblaze   │ │
│ │ DNS         │ │ Stacks      │ │ Items       │ │ Buckets     │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Platform Deployment                         │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │ Docker      │ │ Fly.io      │ │ Vercel      │ │ Cloud       │ │
│ │ Containers  │ │ Apps        │ │ Functions   │ │ Services    │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Service Expansion Logic

### 1. Service Types

```hcl
# Explicit server assignment
docker-grafana = {
  server = "au-hsp"
  storage = {}      # B2 storage detected
  database = {}     # PostgreSQL detected
}

# Cross-server expansion  
docker-caddy = {
  server_include_tag = "reverse_proxy"  # Only deploy to tagged servers
}

# Cloud services
fly-gatus = {
  email = {}        # Resend email detected
  vpn = {}          # Tailscale detected
}
```

### 2. Convention Detection

Features automatically detected from service attributes:

| Attribute | Detected Feature | Generated Resources |
|-----------|------------------|-------------------|
| `dns: [...]` | DNS management | Cloudflare records |
| `storage: {}` | B2 storage | Buckets + keys |
| `database: {}` | Database | Passwords + configs |
| `email: {}` | Email | Resend API keys |
| `username` | Authentication | 1Password items |
| `vpn: {}` | VPN | Tailscale keys |

### 3. Resource Flow

1. **Service Definition** → Services defined in `terraform.tfvars`
2. **Expansion** → Cross-server services expanded to target servers
3. **Feature Detection** → Attributes analyzed for required features
4. **Resource Generation** → Infrastructure resources created per feature
5. **Template Rendering** → Service configs generated from templates
6. **Deployment** → Resources deployed to target platforms

## File Structure

### Core Files
- `locals.tf` - Service processing and feature detection logic  
- `variables.tf` - Input variable definitions
- `outputs.tf` - Infrastructure outputs and service data
- `terraform.tfvars` - Service configurations and credentials

### Resource Files
- `b2.tf` - Backblaze B2 storage
- `cloudflare.tf` - DNS records and zones
- `fly.tf` - Fly.io application deployment
- `onepassword.tf` - Secret management  
- `portainer.tf` - Docker container orchestration
- `random.tf` - Password and secret generation

### Templates
- `templates/docker/` - Docker Compose service definitions
- `templates/gatus/` - Monitoring configurations
- `templates/homepage/` - Homepage dashboard configs

## Data Flow

### Input Processing
```hcl
var.services → services_expanded → services_cross_server → services_merged
                                         ↓
                              services_by_feature (filtered collections)
                                         ↓
                              Resource generation (per provider)
```

### Feature Filtering
```hcl
services_by_feature = {
  dns         = { services with dns attributes }
  database    = { services with database configs }  
  storage     = { services with storage configs }
  auth        = { services with passwords/usernames }
  onepassword = { services needing secret management }
}
```

## Security Model

- **Access Control**: Server-level isolation via Tailscale VPN
- **API Keys**: Stored in Terraform state (encrypted at rest)
- **Passwords**: Auto-generated via `random_password` resources  
- **Secrets**: Managed via 1Password provider
- **Service Isolation**: Each service gets unique credentials

## Extensibility

### Adding New Platforms
1. Create provider configuration in `providers.tf`
2. Add platform detection in service expansion logic
3. Create resource file (e.g., `newplatform.tf`)
4. Add to feature filtering in `services_by_feature`

### Adding New Features
1. Define convention in service expansion
2. Add feature detection logic
3. Create resource generation logic
4. Add template support if needed

## Performance Considerations

- **Parallel Execution**: Resources created in parallel per feature
- **State Management**: Remote state with locking
- **Resource Targeting**: Feature-based filtering reduces resource count
- **Template Caching**: Templates rendered once per service