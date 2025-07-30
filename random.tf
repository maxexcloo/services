resource "random_password" "b2" {
  for_each = local.services_by_feature.b2

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "database_password" {
  for_each = local.services_by_feature.database

  length  = 24
  special = false
}

resource "random_password" "secret_hash" {
  for_each = local.services_by_feature.secret_hash

  length  = 24
  special = false
}

resource "random_password" "sftpgo" {
  for_each = local.services_by_feature.sftpgo

  length  = 24
  special = false
}
