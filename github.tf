data "github_repository" "default" {
  name = var.terraform.github.repository
}

data "github_user" "default" {
  username = var.terraform.github.username
}

resource "github_repository_file" "services_fly_gatus_services" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "gatus"
  }

  file                = "config/${each.key}/services.yaml"
  overwrite_on_create = true
  repository          = var.terraform.github.repository

  content = templatefile(
    "./templates/gatus/services.yaml.tftpl",
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
