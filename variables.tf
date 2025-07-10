variable "default" {
  description = "Default configuration values including domains, email, and service defaults"
  type = object({
    cloud_platforms = list(string)
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
      config                     = map(any)
      description                = string
      dns_content                = optional(string)
      dns_zone                   = optional(string)
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
      filter_exclude_server_flag = string
      filter_include_server_flag = string
      fly                        = map(any)
      fqdn                       = optional(string)
      group                      = string
      icon                       = string
      password                   = string
      port                       = number
      server                     = optional(string)
      server_flags               = list(string)
      server_service             = bool
      service                    = optional(string)
      title                      = string
      url                        = optional(string)
      username                   = optional(string)
      zone                       = string
    })
    widget_config = object({
      filter_exclude_server_flag = string
      filter_include_server_flag = string
      priority                   = number
      widget                     = optional(map(any))
    })
  })
  default = {
    cloud_platforms = ["cloud", "fly", "vercel"]
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
      config                     = {}
      description                = ""
      dns_content                = null
      dns_zone                   = null
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
      filter_exclude_server_flag = ""
      filter_include_server_flag = ""
      fly                        = {}
      fqdn                       = null
      group                      = "Uncategorized"
      icon                       = "homepage"
      password                   = ""
      port                       = 443
      server                     = null
      server_flags               = []
      server_service             = false
      service                    = null
      title                      = ""
      url                        = null
      username                   = null
      zone                       = "external"
    }
    widget_config = {
      filter_exclude_server_flag = ""
      filter_include_server_flag = ""
      priority                   = 0
      widget                     = null
    }
  }
}

variable "services" {
  description = "Service configurations for each platform and environment"
  type        = any
}

variable "tags" {
  default     = {}
  description = "Common tags to apply to all resources"
  type        = map(string)
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
    })
  })
}

