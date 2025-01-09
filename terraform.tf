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
    graphql = {
      source = "sullivtr/graphql"
    }
    onepassword = {
      source = "1password/onepassword"
    }
    random = {
      source = "hashicorp/random"
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
    tfe = {
      source = "hashicorp/tfe"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
