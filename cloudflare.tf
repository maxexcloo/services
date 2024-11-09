data "cloudflare_zone" "service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_dns
  }

  name = each.value.dns_zone
}

resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
}

resource "cloudflare_record" "service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_dns
  }

  allow_overwrite = true
  content         = each.value.dns_proxied ? var.servers[each.value.server].cloudflare_tunnel.cname : each.value.dns_content
  name            = each.value.dns_name
  proxied         = each.value.dns_proxied
  type            = can(cidrhost("${each.value.dns_content}/32", 0)) ? "A" : "CNAME"
  zone_id         = data.cloudflare_zone.service[each.key].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "server" {
  for_each = {
    for k, server in var.servers : k => server
    if contains(server.flags, "cloudflared")
  }

  account_id = cloudflare_account.default.id
  tunnel_id  = each.value.cloudflare_tunnel.id

  config {
    dynamic "ingress_rule" {
      for_each = {
        for k, service in local.merged_services : k => service
        if service.enable_dns && service.server == each.key
      }

      content {
        hostname = cloudflare_record.service[ingress_rule.key].hostname
        service  = "http://localhost"

        origin_request {
          http_host_header = cloudflare_record.service[ingress_rule.key].hostname
        }
      }
    }

    ingress_rule {
      service = "http_status:503"
    }
  }
}
