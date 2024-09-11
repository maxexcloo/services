resource "ssh_resource" "router" {
  for_each = {
    for k, server in var.servers : k => server
    if data.external.connectivity_check_servers[k].result.reachable == "true" && server.tag == "router"
  }

  agent = true
  host  = each.value.host
  port  = each.value.ssh_port
  user  = each.value.ssh_user

  commands = [
    "touch /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg",
    "cat /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg > /etc/haproxy.cfg",
    "/etc/init.d/haproxy restart"
  ]

  file {
    destination = "/etc/haproxy.services.cfg"

    content = templatefile(
      "./templates/openwrt/haproxy.cfg.tftpl",
      {
        servers = var.servers
        services = {
          for k, service in local.merged_services : k => service
          if each.key == try(var.servers[service.server].parent_name, "") && service.dns_zone != var.default.domain_internal && service.fqdn != null
        }
      }
    )
  }
}
