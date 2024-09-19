data "b2_account_info" "default" {}

resource "b2_application_key" "service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_b2
  }

  bucket_id = b2_bucket.service[each.key].id
  key_name  = each.key

  capabilities = [
    "deleteFiles",
    "listBuckets",
    "listFiles",
    "readBucketEncryption",
    "readBucketNotifications",
    "readBucketReplications",
    "readBuckets",
    "readFiles",
    "shareFiles",
    "writeBucketEncryption",
    "writeBucketNotifications",
    "writeBucketReplications",
    "writeFiles"
  ]
}

resource "b2_bucket" "service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_b2
  }

  bucket_name = "${each.key}-${random_password.b2_service[each.key].result}"
  bucket_type = "allPrivate"
}
