resource "bcrypt_hash" "password" {
  for_each = local.filters_services_enable_password

  cleartext = onepassword_item.service[each.key].password
  cost      = 14
}

resource "bcrypt_hash" "secret_hash" {
  for_each = local.outputs_secret_hash_services

  cleartext = each.value
  cost      = 14
}
