# resource "ssh_resource" "router" {
#   for_each = local.merged_routers

#   agent = true
#   host  = each.key
#   port  = each.value.router_port
#   user  = each.value.router_username

#   commands = [
#     "touch /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg",
#     "cat /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg > /etc/haproxy.cfg",
#     "/etc/init.d/haproxy restart"
#   ]

#   file {
#     content     = templatefile("./templates/openwrt/haproxy.cfg.tftpl", each.value)
#     destination = "/etc/haproxy.services.cfg"
#   }
# }
