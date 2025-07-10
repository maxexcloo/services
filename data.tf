data "b2_account_info" "default" {}

data "cloudflare_zones" "unique_zones" {
  for_each = local.unique_dns_zones

  name = each.value

  account = {
    id = var.terraform.cloudflare.account_id
  }
}

data "http" "portainer_endpoints" {
  insecure = true
  url      = "${var.terraform.portainer.url}/api/endpoints"

  request_headers = {
    Content-Type = "application/json"
    X-API-Key    = var.terraform.portainer.api_key
  }
}

data "onepassword_vault" "services" {
  name = var.terraform.onepassword.vault
}

data "tfe_outputs" "infrastructure" {
  organization = "Excloo"
  workspace    = "Infrastructure"
}
