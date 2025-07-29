resource "cloudflare_dns_record" "service" {
  for_each = {
    for k, dns_record in local.services_dns_expanded : k => dns_record
    if contains(keys(data.cloudflare_zones.unique_zones), dns_record.zone)
  }

  comment = "DNS record for ${each.value.service_key} service - ${each.value.hostname}"
  content = local.services_merged[each.value.service_key].enable_cloudflare_proxy ? local.output_servers[local.services_merged[each.value.service_key].server].cloudflare_tunnel.cname : local.services_merged[each.value.service_key].dns_content
  name    = each.value.hostname
  proxied = local.services_merged[each.value.service_key].enable_cloudflare_proxy
  ttl     = 1
  type    = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", local.services_merged[each.value.service_key].dns_content)) ? "A" : (can(regex("^(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$", local.services_merged[each.value.service_key].dns_content)) ? "AAAA" : "CNAME")
  zone_id = data.cloudflare_zones.unique_zones[each.value.zone].result[0].id
}

resource "cloudflare_page_rule" "service_redirects" {
  for_each = {
    for k, dns_record in local.services_dns_expanded : k => dns_record
    if !dns_record.is_primary && contains(keys(data.cloudflare_zones.unique_zones), dns_record.zone)
  }

  priority = 1
  target   = "https://${each.value.hostname}/*"
  zone_id  = data.cloudflare_zones.unique_zones[each.value.zone].result[0].id

  actions = {
    forwarding_url = {
      status_code = 301
      url         = "https://${local.services_computations[each.value.service_key].primary_hostname}/$1"
    }
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "server" {
  for_each = local.output_servers

  account_id = var.terraform.cloudflare.account_id
  source     = "cloudflare"
  tunnel_id  = each.value.cloudflare_tunnel.id

  config = {
    ingress = concat(
      flatten([
        for k, dns_record in local.services_dns_expanded : [
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
        ] if contains(keys(data.cloudflare_zones.unique_zones), dns_record.zone) && local.services_merged[dns_record.service_key].enable_cloudflare_proxy && local.services_merged[dns_record.service_key].server == each.key
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
