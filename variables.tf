variable "default" {
  description = "Default configuration values including domains, email, and service defaults"
  type = object({
    domain_external = string
    domain_internal = string
    domain_root     = string
    email           = string
    name            = string
    oidc_name       = string
    oidc_title      = string
    oidc_url        = string
    organisation    = string
    service_config = object({
      description                = string
      filter_exclude_server_flag = string
      filter_include_server_flag = string
      group                      = string
      icon                       = string
      password                   = string
      port                       = number
      title                      = string
      zone                       = string
      dns_content                = optional(string)
      dns_zone                   = optional(string)
      fqdn                       = optional(string)
      server                     = optional(string)
      service                    = optional(string)
      url                        = optional(string)
      username                   = optional(string)
      enable_b2                  = bool
      enable_cloudflare_proxy    = bool
      enable_database_password   = bool
      enable_dns                 = bool
      enable_href                = bool
      enable_monitoring          = bool
      enable_password            = bool
      enable_resend              = bool
      enable_secret_hash         = bool
      enable_sftpgo              = bool
      enable_ssl                 = bool
      enable_ssl_validation      = bool
      enable_tailscale           = bool
      server_service             = bool
      config                     = map(any)
      fly                        = map(any)
      server_flags               = list(string)
    })
    widget_config = object({
      filter_exclude_server_flag = string
      filter_include_server_flag = string
      priority                   = number
      widget                     = optional(map(any))
    })
    cloud_platforms = list(string)
  })
  default = {
    domain_external = "excloo.net"
    domain_internal = "excloo.org"
    domain_root     = "excloo.com"
    email           = "max@excloo.com"
    name            = "Max Schaefer"
    oidc_name       = "pocket-id"
    oidc_title      = "Pocket ID"
    oidc_url        = "https://id.excloo.com"
    organisation    = "excloo"
    service_config = {
      description                = ""
      filter_exclude_server_flag = ""
      filter_include_server_flag = ""
      group                      = "Uncategorized"
      icon                       = "homepage"
      password                   = ""
      port                       = 443
      title                      = ""
      zone                       = "external"
      dns_content                = null
      dns_zone                   = null
      fqdn                       = null
      server                     = null
      service                    = null
      url                        = null
      username                   = null
      enable_b2                  = false
      enable_cloudflare_proxy    = false
      enable_database_password   = false
      enable_dns                 = false
      enable_href                = true
      enable_monitoring          = true
      enable_password            = false
      enable_resend              = false
      enable_secret_hash         = false
      enable_sftpgo              = false
      enable_ssl                 = true
      enable_ssl_validation      = true
      enable_tailscale           = false
      server_service             = false
      config                     = {}
      fly                        = {}
      server_flags               = []
    }
    widget_config = {
      filter_exclude_server_flag = ""
      filter_include_server_flag = ""
      priority                   = 0
      widget                     = null
    }
    cloud_platforms = ["cloud", "fly", "vercel"]
  }
}

variable "services" {
  description = "Service configurations for each platform and environment"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.services : v != null && v != {}
    ])
    error_message = "Service configurations cannot be null or empty."
  }

  validation {
    condition = alltrue([
      for k, v in var.services : can(regex("^[a-z][a-z0-9-]*-[a-z][a-z0-9-]*$", k))
    ])
    error_message = "Service keys must follow the pattern 'platform-servicename' with lowercase letters, numbers, and hyphens only."
  }
}

variable "tags" {
  default     = {}
  description = "Common tags to apply to all resources"
  type        = map(string)

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", k))
    ])
    error_message = "Tag keys must start with a letter and contain only alphanumeric characters, underscores, and hyphens."
  }
}

variable "terraform" {
  description = "Terraform provider configurations and API credentials"
  sensitive   = true
  type = object({
    b2 = object({
      application_key    = string
      application_key_id = string
    })
    cloudflare = object({
      account_id = string
      api_key    = string
    })
    fly = object({
      api_token = string
      org       = string
      url       = string
    })
    onepassword = object({
      service_account_token = string
      vault                 = string
    })
    portainer = object({
      api_key = string
      url     = string
    })
    resend = object({
      api_key       = string
      smtp_host     = string
      smtp_port     = number
      smtp_username = string
      url           = string
    })
    sftpgo = object({
      home_directory_base = string
      host                = string
      password            = string
      username            = string
      webdav_url          = string
    })
    tailscale = object({
      oauth_client_id     = string
      oauth_client_secret = string
      organization        = string
    })
  })
}
