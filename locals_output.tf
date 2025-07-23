locals {
  output_b2 = {
    for k, b2_bucket in b2_bucket.service : k => {
      application_key    = b2_application_key.service[k].application_key
      application_key_id = b2_application_key.service[k].application_key_id
      bucket_name        = b2_bucket.bucket_name
      endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
    }
  }

  output_databases = {
    for k, service in local.services_merged : k => {
      name     = service.service
      password = random_password.database_password[k].result
      username = service.service
    }
    if service.enable_database_password
  }

  output_portainer_stacks = {
    for k, service in local.services_merged_outputs : k => service
    if service.platform == "docker" && service.portainer_endpoint_id != "" && service.service != null
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_service : k => sensitive(jsondecode(restapi_object.create_response).token)
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash : k => random_password.result
  }

  output_servers = nonsensitive(jsondecode(data.tfe_outputs.infrastructure.values.servers))

  output_sftpgo = {
    for k, sftpgo_user in sftpgo_user.service : k => {
      home_directory = sftpgo_user.home_dir
      password       = sftpgo_user.password
      username       = sftpgo_user.username
      webdav_url     = var.terraform.sftpgo.webdav_url
    }
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.service : k => tailscale_tailnet_key.key
  }
}