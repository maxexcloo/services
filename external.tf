data "external" "connectivity_check_servers" {
  for_each = var.servers

  program = ["sh", "-c", "nc -w 3 -z ${each.value.host} ${each.value.ssh_port} >/dev/null 2>&1 && echo '{\"reachable\": \"true\"}' || echo '{\"reachable\": \"false\"}'"]
}
