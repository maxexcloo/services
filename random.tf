resource "random_password" "b2" {
  for_each = {
    for k, service in local.filtered_services_all : k => service
    if service.enable_b2
  }

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "database_password" {
  for_each = {
    for k, service in local.filtered_services_all : k => service
    if service.database_username != null
  }

  length  = 24
  special = false
}

resource "random_password" "secret_hash" {
  for_each = {
    for k, service in local.filtered_services_all : k => service
    if service.enable_secret_hash
  }

  length  = 24
  special = false
}
