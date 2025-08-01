resource "onepassword_item" "service" {
  for_each = local.services_by_feature.onepassword

  category = "login"
  password = try(each.value.enable_password, false) || try(each.value.password, "") == "" ? null : try(each.value.password, null)
  title    = "${each.value.title} (${try(each.value.server, null) != null ? each.value.server : each.value.platform})"
  url      = try(each.value.url, null)
  username = try(each.value.username, "") != "" ? each.value.username : null
  vault    = data.onepassword_vault.services.uuid

  dynamic "password_recipe" {
    for_each = try(each.value.enable_password, false) ? [true] : []

    content {
      length  = 24
      symbols = false
    }
  }

  dynamic "section" {
    for_each = each.value.has_b2 ? [true] : []

    content {
      label = "B2"

      field {
        label = "B2 Application Key"
        type  = "CONCEALED"
        value = local.output_b2[each.key].application_key
      }

      field {
        label = "B2 Application Key ID"
        type  = "STRING"
        value = local.output_b2[each.key].application_key_id
      }

      field {
        label = "B2 Bucket Name"
        type  = "STRING"
        value = local.output_b2[each.key].bucket_name
      }

      field {
        label = "B2 Endpoint"
        type  = "URL"
        value = local.output_b2[each.key].endpoint
      }
    }
  }

  dynamic "section" {
    for_each = each.value.has_database ? [true] : []

    content {
      label = "Database"

      field {
        label = "Database Name"
        type  = "STRING"
        value = local.output_databases[each.key].name
      }

      field {
        label = "Database Username"
        type  = "STRING"
        value = local.output_databases[each.key].username
      }

      field {
        label = "Database Password"
        type  = "CONCEALED"
        value = local.output_databases[each.key].password
      }
    }
  }

  dynamic "section" {
    for_each = contains(keys(local.services_mail_section), each.key) ? [true] : []

    content {
      label = "Mail"

      field {
        label = "SMTP Host"
        type  = "STRING"
        value = var.terraform.resend.smtp_host
      }

      field {
        label = "SMTP Port"
        type  = "STRING"
        value = var.terraform.resend.smtp_port
      }

      field {
        label = "SMTP Username"
        type  = "STRING"
        value = var.terraform.resend.smtp_username
      }

      field {
        label = "SMTP Password"
        type  = "CONCEALED"
        value = try(local.output_resend_api_keys[each.key], local.output_servers[each.value.server].resend_api_key, "")
      }
    }
  }

  dynamic "section" {
    for_each = each.value.has_resend ? [true] : []

    content {
      label = "Resend"

      field {
        label = "Resend API Key"
        type  = "CONCEALED"
        value = local.output_resend_api_keys[each.key]
      }
    }
  }

  dynamic "section" {
    for_each = each.value.has_secret_hash ? [true] : []

    content {
      label = "Secret Hash"

      field {
        label = "Secret Hash"
        type  = "CONCEALED"
        value = local.output_secret_hashes[each.key]
      }
    }
  }

  dynamic "section" {
    for_each = each.value.has_sftpgo ? [true] : []

    content {
      label = "SFTPGo"

      field {
        label = "SFTPGo Username"
        type  = "STRING"
        value = local.output_sftpgo[each.key].username
      }

      field {
        label = "SFTPGo Password"
        type  = "CONCEALED"
        value = local.output_sftpgo[each.key].password
      }

      field {
        label = "SFTPGo Home Directory"
        type  = "STRING"
        value = local.output_sftpgo[each.key].home_directory
      }

      field {
        label = "SFTPGo WebDAV URL"
        type  = "URL"
        value = local.output_sftpgo[each.key].webdav_url
      }
    }
  }

  dynamic "section" {
    for_each = each.value.has_tailscale ? [true] : []

    content {
      label = "Tailscale"

      field {
        label = "Tailscale Tailnet Key"
        type  = "CONCEALED"
        value = local.output_tailscale_tailnet_keys[each.key]
      }
    }
  }
}
