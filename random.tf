resource "random_password" "b2" {
  for_each = local.filtered_services_b2

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "database_password" {
  for_each = local.filtered_services_database_password

  length  = 24
  special = false
}

resource "random_password" "secret_hash" {
  for_each = local.filtered_services_secret_hash

  length  = 24
  special = false
}

resource "random_password" "sftpgo" {
  for_each = local.filtered_services_sftpgo

  length  = 24
  special = false
}
