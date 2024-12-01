resource "bcrypt_hash" "password" {
  for_each = {
    for k, service in onepassword_item.service : k => service
    if local.merged_services[k].enable_password
  }

  cleartext = each.value.password
  cost      = 14
}

resource "bcrypt_hash" "secret_hash" {
  for_each = local.output_secret_hashes

  cleartext = each.value
  cost      = 14
}
