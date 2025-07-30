variable "default" {
  description = "Default configuration values"
  type = object({
    domains = object({
      external = string
      internal = string
      root     = string
    })
    email        = string
    name         = string
    organisation = string
    oidc = object({
      name  = string
      title = string
      url   = string
    })
    platforms = list(string)
  })

  default = {
    domains = {
      external = "excloo.net"
      internal = "excloo.org"
      root     = "excloo.com"
    }
    email        = "max@excloo.com"
    name         = "Max Schaefer"
    organisation = "excloo"
    oidc = {
      name  = "pocket-id"
      title = "Pocket ID"
      url   = "https://id.excloo.com"
    }
    platforms = ["cloud", "fly", "vercel"]
  }
}

variable "services" {
  description = "Service configurations using convention over configuration"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.services : can(regex("^[a-z][a-z0-9-]*-[a-z][a-z0-9-]*$", k))
    ])
    error_message = "Service keys must follow 'platform-servicename' pattern."
  }
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}

variable "terraform" {
  description = "Provider configurations and credentials"
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
