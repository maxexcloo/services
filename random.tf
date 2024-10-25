resource "random_password" "b2_service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_b2
  }

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "database_service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_database
  }

  length  = 24
  special = false
}

resource "random_password" "secret_hash_service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_secret_hash
  }

  length  = 24
  special = false
}
