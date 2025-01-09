data "onepassword_vault" "services" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "service" {
  for_each = local.filtered_onepassword_services

  category = "login"
  password = each.value.enable_password || each.value.password == "" ? null : each.value.password
  title    = "${each.value.title} (${each.value.server != null ? each.value.server : each.value.platform})"
  url      = try(templatestring(each.value.url, { default = var.default, server = try(local.merged_servers[each.value.server], null), service = each.value }), null)
  username = each.value.username
  vault    = data.onepassword_vault.services.uuid

  dynamic "password_recipe" {
    for_each = each.value.enable_password ? [true] : []

    content {
      length  = 24
      symbols = false
    }
  }

  dynamic "section" {
    for_each = each.value.enable_b2 ? [true] : []

    content {
      label = "B2"

      field {
        label = "Application Key"
        type  = "CONCEALED"
        value = local.output_b2[each.key].application_key
      }

      field {
        label = "Application Key ID"
        type  = "STRING"
        value = local.output_b2[each.key].application_key_id
      }

      field {
        label = "Bucket Name"
        type  = "STRING"
        value = local.output_b2[each.key].bucket_name
      }

      field {
        label = "Endpoint"
        type  = "URL"
        value = local.output_b2[each.key].endpoint
      }
    }
  }

  dynamic "section" {
    for_each = each.value.database_name != null || each.value.database_username != null ? [true] : []

    content {
      label = "Database Name"

      field {
        label = "Name"
        type  = "STRING"
        value = each.value.database_name
      }

      field {
        label = "Username"
        type  = "STRING"
        value = each.value.database_username
      }

      field {
        label = "Password"
        type  = "CONCEALED"
        value = local.output_databases[each.key].password
      }
    }
  }

  dynamic "section" {
    for_each = each.value.enable_resend ? [true] : []

    content {
      label = "Resend"

      field {
        label = "API Key"
        type  = "CONCEALED"
        value = local.output_resend_api_keys[each.key]
      }
    }
  }

  dynamic "section" {
    for_each = each.value.enable_secret_hash ? [true] : []

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
    for_each = each.value.enable_tailscale ? [true] : []

    content {
      label = "Tailscale"

      field {
        label = "Tailnet Key"
        type  = "CONCEALED"
        value = local.output_tailscale_tailnet_keys[each.key]
      }
    }
  }
}
