terraform {
  required_version = ">= 1.8"

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Excloo"

    workspaces {
      name = "Services"
    }
  }

  required_providers {
    b2 = {
      source  = "backblaze/b2"
      version = "~> 0.10"
    }
    bcrypt = {
      source  = "viktorradnai/bcrypt"
      version = "~> 0.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    onepassword = {
      source  = "1password/onepassword"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    restapi = {
      source  = "mastercard/restapi"
      version = "~> 2.0"
    }
    sftpgo = {
      source  = "drakkan/sftpgo"
      version = "~> 0.0.14"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.20"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.68"
    }
  }
}
