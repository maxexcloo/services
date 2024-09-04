# resource "ssh_resource" "router" {
#   for_each = local.merged_routers

#   agent = true
#   host  = each.key
#   port  = each.value.network.ssh_port
#   user  = each.value.user.username

#   commands = [
#     "touch /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg",
#     "cat /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg > /etc/haproxy.cfg",
#     "/etc/init.d/haproxy restart"
#   ]

#   file {
#     destination = "/etc/haproxy.services.cfg"

#     content = templatefile(
#       "./templates/openwrt/haproxy.cfg.tftpl",
#       {
#         services = {
#           for k, v in local.filtered_services_noncloud : k => v
#           if k != each.value.location && v.location == each.value.location
#         }
#       }
#     )
#   }
# }
