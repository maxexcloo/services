data "cloudflare_zone" "service" {
  for_each = local.filtered_services_enable_dns

  name = each.value.dns_zone
}

resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
}

resource "cloudflare_record" "service" {
  for_each = local.filtered_services_enable_dns

  allow_overwrite = true
  content         = each.value.enable_cloudflare_proxy ? local.merged_servers[each.value.server].cloudflare_tunnel.cname : each.value.dns_content
  name            = each.value.dns_name
  proxied         = each.value.enable_cloudflare_proxy
  type            = can(cidrhost("${each.value.dns_content}/32", 0)) ? "A" : "CNAME"
  zone_id         = data.cloudflare_zone.service[each.key].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "server" {
  for_each = {
    for k, server in local.merged_servers : k => server
    if contains(server.flags, "cloudflared")
  }

  account_id = cloudflare_account.default.id
  tunnel_id  = each.value.cloudflare_tunnel.id

  config {
    dynamic "ingress_rule" {
      for_each = {
        for k, service in local.filtered_services_enable_dns : k => service
        if service.enable_cloudflare_proxy && service.server == each.key
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
