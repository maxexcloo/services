resource "random_password" "b2" {
  for_each = local.filters_services_enable_b2

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "database_password" {
  for_each = {
    for k, service in local.services_merged : k => service
    if service.enable_database_password
  }

  length  = 24
  special = false
}

resource "random_password" "secret_hash" {
  for_each = {
    for k, service in local.services_merged : k => service
    if service.enable_secret_hash
  }

  length  = 24
  special = false
}

resource "random_password" "sftpgo" {
  for_each = local.filters_services_enable_sftpgo

  length  = 24
  special = false
}
