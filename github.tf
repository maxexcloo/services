data "github_user" "default" {
  username = ""
}

resource "github_repository_file" "services_fly_gatus_services" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.service == "gatus"
  }

  file                = "fly/${each.value.name}/config/services.yaml"
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

resource "github_repository_file" "services_docker_mapping" {
  file                = "docker/_mapping.json"
  overwrite_on_create = true
  repository          = "Services"

  content = jsonencode({
    for service_name in distinct([
      for service in local.merged_services : service.service
      if service.platform == "docker" && service.service != ""
    ]) :
    service_name => [
      for service in local.merged_services : service.server
      if service.platform == "docker" && service.server != "" && service.service == service_name
    ]
  })
}
