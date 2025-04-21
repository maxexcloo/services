resource "restapi_object" "resend_api_key_service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_resend
  }

  data         = jsonencode({ name = each.key })
  id_attribute = "id"
  path         = "/api-keys"
  provider     = restapi.resend
  read_path    = "/api-keys"

  ignore_changes_to = [
    "created_at",
    "id"
  ]

  read_search = {
    query_string = ""
    results_key  = "data"
    search_key   = "name"
    search_value = each.key
  }
}
