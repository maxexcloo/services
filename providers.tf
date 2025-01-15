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

provider "graphql" {
  alias = "fly"
  url   = var.terraform.fly.url_graphql

  headers = {
    Authorization = "Bearer ${var.terraform.fly.api_token}"
  }
}

provider "onepassword" {
  service_account_token = var.terraform.onepassword.service_account_token
}

provider "restapi" {
  alias                = "fly"
  id_attribute         = "id"
  uri                  = var.terraform.fly.url_rest
  write_returns_object = true

  headers = {
    Authorization = "Bearer ${var.terraform.fly.api_token}"
    Content-Type  = "application/json"
  }
}

provider "restapi" {
  alias                = "portainer"
  id_attribute         = "Id"
  insecure             = true
  rate_limit           = 10
  uri                  = "${var.terraform.portainer.url}/api"
  write_returns_object = true

  headers = {
    Content-Type = "application/json"
    X-API-Key    = var.terraform.portainer.api_key
  }
}

provider "restapi" {
  alias                 = "resend"
  create_returns_object = true
  rate_limit            = 1
  uri                   = var.terraform.resend.url

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
