resource "cloudflare_dns_record" "service" {
  for_each = local.filtered_services_dns

  comment = "DNS record for ${each.key} service"
  content = each.value.enable_cloudflare_proxy ? local.output_servers[each.value.server].cloudflare_tunnel.cname : each.value.dns_content
  name    = "${each.value.dns_name}.${each.value.dns_zone}"
  proxied = each.value.enable_cloudflare_proxy
  ttl     = 1
  type    = local.services_dns_record_types[each.key]
  zone_id = data.cloudflare_zones.unique_zones[each.value.dns_zone].result[0].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "server" {
  for_each = local.output_servers

  account_id = var.terraform.cloudflare.account_id
  source     = "cloudflare"
  tunnel_id  = each.value.cloudflare_tunnel.id

  config = {
    ingress = concat(
      flatten([
        for k, service in local.filtered_services_dns : [
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

    warp_routing = {
      enabled = false
    }
  }
}
