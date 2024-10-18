data "github_repository" "default" {
  name = var.terraform.github.repository
}

data "github_user" "default" {
  username = var.terraform.github.username
}

resource "github_repository_deploy_key" "service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_github_deploy_key
  }

  key        = local.output_github[each.key].deploy_public_key
  read_only  = true
  repository = each.value.github_repo
  title      = each.key
}

resource "github_repository_file" "services_config_gatus_services" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "gatus"
  }

  file                = "config/${each.key}/services.yaml"
  overwrite_on_create = true
  repository          = var.terraform.github.repository

  content = templatefile(
    "./templates/${each.value.service}/services.yaml.tftpl",
    {
      default = var.default
      gatus   = each.value

      services = {
        for k, service in local.merged_services : k => service
        if service.fqdn != null
      }
    }
  )
}

resource "github_repository_file" "services_config_homepage_bookmarks" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }

  content             = templatefile("./templates/${each.value.service}/bookmarks.yaml.tftpl", { homepage = each.value })
  file                = "config/${each.key}/bookmarks.yaml"
  overwrite_on_create = true
  repository          = var.terraform.github.repository
}

resource "github_repository_file" "services_config_homepage_services" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }

  content             = templatefile("./templates/${each.value.service}/services.yaml.tftpl", { homepage = each.value })
  file                = "config/${each.key}/services.yaml"
  overwrite_on_create = true
  repository          = var.terraform.github.repository
}

resource "github_repository_file" "services_config_homepage_settings" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "homepage"
  }

  content             = templatefile("./templates/${each.value.service}/settings.yaml.tftpl", { homepage = each.value })
  file                = "config/${each.key}/settings.yaml"
  overwrite_on_create = true
  repository          = var.terraform.github.repository
}
