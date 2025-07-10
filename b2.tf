resource "b2_application_key" "service" {
  for_each = b2_bucket.service

  bucket_id = each.value.id
  key_name  = each.key

  capabilities = [
    "deleteFiles",
    "listFiles",
    "readFiles",
    "writeFiles"
  ]
}

resource "b2_bucket" "service" {
  for_each = local.filters_services_enable_b2

  bucket_name = "${each.key}-${random_password.b2[each.key].result}"
  bucket_type = "allPrivate"
}
