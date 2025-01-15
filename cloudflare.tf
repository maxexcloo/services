data "cloudflare_api_token_permission_groups" "default" {}

data "cloudflare_zone" "internal" {
  name = var.default.domain_internal
}

data "cloudflare_zone" "service" {
  for_each = local.filtered_services_enable_dns

  name = each.value.dns_zone
}

resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
}

resource "cloudflare_api_token" "internal" {
  name = "internal"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.default.zone["DNS Write"],
      data.cloudflare_api_token_permission_groups.default.zone["Zone Read"]
    ]
    resources = {
      "com.cloudflare.api.account.zone.${data.cloudflare_zone.internal.id}" = "*"
    }
  }
}

resource "cloudflare_record" "service" {
  for_each = local.filtered_services_enable_dns

  allow_overwrite = true
  content         = each.value.enable_proxy ? local.output_servers[each.value.server].cloudflare_tunnel.cname : each.value.dns_content
  name            = each.value.dns_name
  proxied         = each.value.enable_proxy
  type            = can(cidrhost("${each.value.dns_content}/32", 0)) ? "A" : "CNAME"
  zone_id         = data.cloudflare_zone.service[each.key].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "server" {
  for_each = local.output_servers

  account_id = cloudflare_account.default.id
  tunnel_id  = each.value.cloudflare_tunnel.id

  config {
    dynamic "ingress_rule" {
      for_each = {
        for k, service in local.filtered_services_enable_dns : k => service
        if service.enable_proxy && service.server == each.key
      }

      content {
        hostname = cloudflare_record.service[ingress_rule.key].hostname
        path     = "/.well-known/acme-challenge/*"
        service  = "http://localhost"

        origin_request {
          http_host_header = cloudflare_record.service[ingress_rule.key].hostname
        }
      }
    }

    dynamic "ingress_rule" {
      for_each = {
        for k, service in local.filtered_services_enable_dns : k => service
        if service.enable_proxy && service.server == each.key
      }

      content {
        hostname = cloudflare_record.service[ingress_rule.key].hostname
        service  = "https://localhost"

        origin_request {
          no_tls_verify      = true
          origin_server_name = cloudflare_record.service[ingress_rule.key].hostname
        }
      }
    }

    ingress_rule {
      service = "http_status:503"
    }
  }
}
