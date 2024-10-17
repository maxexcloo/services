resource "tls_private_key" "github_deploy_key_service" {
  for_each = {
    for k, service in local.merged_services : k => service
    if service.enable_github_deploy_key
  }

  algorithm = "ED25519"
}
