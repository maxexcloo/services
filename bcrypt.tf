resource "bcrypt_hash" "service" {
  for_each = local.output_secret_hashes

  cleartext = each.value
  cost      = 14
}
