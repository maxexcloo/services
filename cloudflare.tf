data "cloudflare_zone" "service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_dns
  }

  name = each.value.dns_zone
}

resource "cloudflare_record" "service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_dns
  }

  allow_overwrite = true
  content         = each.value.dns_content
  name            = each.value.dns_name
  type            = length(regexall("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", each.value.dns_content)) > 0 ? "A" : "CNAME"
  zone_id         = data.cloudflare_zone.service[each.key].id
}
