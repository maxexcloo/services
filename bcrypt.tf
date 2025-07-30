resource "bcrypt_hash" "password" {
  for_each = local.services_by_feature.auth

  cleartext = onepassword_item.service[each.key].password
  cost      = 14
}

resource "bcrypt_hash" "secret_hash" {
  for_each = local.services_by_feature.secret_hash

  cleartext = random_password.secret_hash[each.key].result
  cost      = 14
}
