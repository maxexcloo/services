provider "b2" {
  application_key    = var.terraform.b2.application_key
  application_key_id = var.terraform.b2.application_key_id
}

provider "cloudflare" {
  api_key = var.terraform.cloudflare.api_key
  email   = var.terraform.cloudflare.email
}

provider "github" {
  token = var.terraform.github.token
}

provider "onepassword" {
  service_account_token = var.terraform.onepassword.service_account_token
}

provider "restapi" {
  alias                = "portainer"
  id_attribute         = "Id"
  uri                  = var.terraform.portainer.url
  write_returns_object = true

  headers = {
    X-API-Key = var.terraform.portainer.api_key
  }
}

provider "restapi" {
  alias                 = "resend"
  create_returns_object = true
  rate_limit            = 1
  uri                   = "https://api.resend.com"

  headers = {
    "Authorization" = "Bearer ${var.terraform.resend.api_key}",
    "Content-Type"  = "application/json"
  }
}

provider "tailscale" {
  oauth_client_id     = var.terraform.tailscale.oauth_client_id
  oauth_client_secret = var.terraform.tailscale.oauth_client_secret
  tailnet             = var.default.domain_root
}
