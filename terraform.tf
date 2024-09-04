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
    ssh = {
      source = "loafoe/ssh"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}
