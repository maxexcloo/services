resource "random_password" "b2_service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_b2
  }

  length  = 6
  special = false
  upper   = false
}
