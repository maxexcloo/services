data "github_user" "default" {
  username = ""
}

resource "github_repository_file" "gatus_services" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "gatus"
  }

  file                = "fly/gatus/config/services.yaml"
  overwrite_on_create = true
  repository          = "Services"

  content = templatefile(
    "./templates/gatus/services.yaml.tftpl",
    {
      default  = var.default
      gatus    = each.value
      services = local.merged_services
    }
  )
}
