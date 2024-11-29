terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Excloo"

    workspaces {
      name = "Services"
    }
  }

  required_providers {
    b2 = {
      source = "backblaze/b2"
    }
    bcrypt = {
      source = "viktorradnai/bcrypt"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    github = {
      source = "integrations/github"
    }
    onepassword = {
      source = "1password/onepassword"
    }
    restapi = {
      source = "mastercard/restapi"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}
