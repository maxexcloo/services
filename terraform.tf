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
    onepassword = {
      source = "1password/onepassword"
    }
    sftpgo = {
      source = "drakkan/sftpgo"
    }
    restapi = {
      source = "mastercard/restapi"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
    tfe = {
      source = "hashicorp/tfe"
    }
  }
}
