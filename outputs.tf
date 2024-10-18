output "b2" {
  sensitive = true
  value     = local.output_b2
}

output "databases" {
  sensitive = true
  value     = local.output_databases
}

output "github" {
  sensitive = true
  value     = local.output_github
}

output "resend" {
  sensitive = true
  value     = local.output_resend
}

output "services" {
  sensitive = true
  value     = local.merged_services
}

output "secret_hashes" {
  sensitive = true
  value     = local.output_secret_hashes
}

output "tailscale" {
  sensitive = true
  value     = local.output_tailscale
}

resource "local_file" "config_gatus" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "gatus"
  }

  filename = "config/${each.key}/services.yaml"

  content = templatefile(
    "templates/${each.value.service}/services.yaml.tftpl",
    {
      default  = var.default
      gatus    = each.value
      servers  = var.servers
      services = local.merged_services
      tags     = var.tags
    }
  )
}

resource "local_file" "config_homepage_bookmarks" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }

  filename = "config/${each.key}/bookmarks.yaml"

  content = templatefile(
    "templates/${each.value.service}/bookmarks.yaml.tftpl",
    {
      homepage = each.value
      servers  = var.servers
      services = local.merged_services
      tags     = var.tags
    }
  )
}

resource "local_file" "config_homepage_docker" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }

  filename = "config/${each.key}/docker.yaml"

  content = templatefile(
    "templates/${each.key}/docker.yaml.tftpl",
    {
      servers = var.servers
      tags    = var.tags
    }
  )
}

resource "local_file" "config_homepage_kubernetes" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }

  filename = "config/${each.key}/kubernetes.yaml"

  content = templatefile(
    "templates/${each.key}/kubernetes.yaml.tftpl",
    {
      servers = var.servers
      tags    = var.tags
    }
  )
}

resource "local_file" "config_homepage_services" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }
  filename = "config/${each.key}/services.yaml"

  content = templatefile(
    "templates/${each.value.service}/services.yaml.tftpl",
    {
      homepage = each.value
      servers  = var.servers
      services = local.merged_services
      tags     = var.tags
    }
  )
}

resource "local_file" "config_homepage_settings" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }

  content  = templatefile("templates/${each.value.service}/settings.yaml.tftpl", { homepage = each.value })
  filename = "config/${each.key}/settings.yaml"
}

resource "local_file" "config_homepage_widgets" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }

  filename = "config/${each.key}/widgets.yaml"

  content = templatefile(
    "templates/${each.value.service}/widgets.yaml.tftpl",
    {
      servers = var.servers
      tags    = var.tags
    }
  )
}