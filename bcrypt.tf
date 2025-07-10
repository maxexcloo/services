resource "bcrypt_hash" "password" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_password
  }

  cleartext = onepassword_item.service[each.key].password
  cost      = 14
}

resource "bcrypt_hash" "secret_hash" {
  for_each = local.secret_hash_services

  cleartext = each.value
  cost      = 14
}
