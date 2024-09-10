data "github_repository" "default" {
  name = basename(path.module)
}

data "github_user" "default" {
  username = var.terraform.github.username
}

resource "github_repository_file" "services_fly_gatus_services" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "gatus"
  }

  file                = "fly/${each.key}/config/services.yaml"
  overwrite_on_create = true
  repository          = "Services"

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
