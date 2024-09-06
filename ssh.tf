resource "ssh_resource" "router" {
  for_each = {
    for k, server in var.servers : k => server
    if data.external.connectivity_check_servers[k].result.reachable == "true" && server.tag == "router"
  }

  agent = true
  host  = each.value.host
  port  = each.value.ssh_port
  user  = each.value.username

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
        services = {
          for k, service in local.merged_services : k => service
          if each.key == try(var.servers[service.server].parent_name, "")
        }
        servers = var.servers
      }
    )
  }
}

resource "ssh_resource" "server_docker" {
  for_each = {
    for k, server in var.servers : k => server
    if data.external.connectivity_check_servers[k].result.reachable == "true" && contains(server.flags, "docker")
  }

  agent = true
  host  = each.value.host
  port  = each.value.ssh_port
  user  = each.value.username

  commands = [
    "mkdir -p ~/.env"
  ]

  dynamic "file" {
    for_each = {
      for k, service in local.merged_services : k => service
      if each.key == service.server
    }

    content {
      destination = "~/.env/${file.value.service}.env"

      content = join("\n", concat(
        try(file.value.dns_name, "") != "" && try(file.value.dns_zone, "") != "" ? [
          "SERVICE_FQDN=\"${file.value.fqdn}\"",
          "SERVICE_URL=\"${file.value.url}\"",
        ] : [],
        file.value.enable_b2 ? [
          "SERVICE_B2_BUCKET_APPLICATION_KEY=\"${local.output_b2[file.key].application_key}\"",
          "SERVICE_B2_BUCKET_APPLICATION_SECRET=\"${local.output_b2[file.key].application_secret}\"",
          "SERVICE_B2_BUCKET_BUCKET_NAME=\"${local.output_b2[file.key].bucket_name}\"",
          "SERVICE_B2_BUCKET_ENDPOINT=\"${local.output_b2[file.key].endpoint}\"",
        ] : [],
        file.value.enable_database ? [
          "SERVICE_DATABASE_PASSWORD=\"${local.output_databases[file.key].password}\"",
        ] : [],
        file.value.enable_resend ? [
          "SERVICE_RESEND_API_KEY=\"${local.output_resend[file.key].api_key}\"",
        ] : [],
        file.value.enable_secret_hash ? [
          "SERVICE_SECRET_HASH=\"${local.output_secret_hashes[file.key].secret_hash}\"",
        ] : [],
        file.value.enable_tailscale ? [
          "SERVICE_TAILSCALE_TAILNET_KEY=\"${local.output_tailscale[file.key].tailnet_key}\"",
        ] : [],
        [""]
      ))
    }
  }
}
