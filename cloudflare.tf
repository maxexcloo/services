data "cloudflare_zones" "service" {
  for_each = local.filtered_services_enable_dns

  name = each.value.dns_zone

  account = {
    id = cloudflare_account.default.id
  }
}

resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
  type = "standard"
}

resource "cloudflare_dns_record" "service" {
  for_each = local.filtered_services_enable_dns

  content = each.value.enable_cloudflare_proxy ? local.output_servers[each.value.server].cloudflare_tunnel.cname : each.value.dns_content
  name    = "${each.value.dns_name}.${each.value.dns_zone}"
  proxied = each.value.enable_cloudflare_proxy
  ttl     = 1
  type    = can(cidrhost("${each.value.dns_content}/32", 0)) ? "A" : "CNAME"
  zone_id = element(data.cloudflare_zones.service[each.key].result, 0).id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "server" {
  for_each = local.output_servers

  account_id = cloudflare_account.default.id
  tunnel_id  = each.value.cloudflare_tunnel.id

  config = {
    ingress = concat(
      flatten([
        for k, service in local.filtered_services_enable_dns : [
          {
            hostname = cloudflare_dns_record.service[k].name
            path     = "/.well-known/acme-challenge/*"
            service  = "http://localhost"

            origin_request = {
              http_host_header = cloudflare_dns_record.service[k].name
            }
          },
          {
            hostname = cloudflare_dns_record.service[k].name
            service  = "https://localhost"

            origin_request = {
              no_tls_verify      = true
              origin_server_name = cloudflare_dns_record.service[k].name
            }
          }
        ] if service.enable_cloudflare_proxy && service.server == each.key
      ]),
      [
        {
          service = "http_status:503"
        }
      ]
    )
  }
}
