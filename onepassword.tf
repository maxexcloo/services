data "onepassword_item" "service" {
  for_each = onepassword_item.service

  uuid  = each.value.uuid
  vault = data.onepassword_vault.services.uuid
}

data "onepassword_vault" "services" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "service" {
  for_each = local.merged_services

  category = "login"
  title    = each.value.description
  url      = each.value.url
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
        type  = "STRING"
        value = local.output_b2[each.key].application_key
      }

      field {
        label = "Application Secret"
        type  = "CONCEALED"
        value = local.output_b2[each.key].application_secret
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
    for_each = each.value.enable_database ? [true] : []

    content {
      label = "Database"

      field {
        label = "Password"
        type  = "CONCEALED"

        password_recipe {
          length  = 24
          symbols = false
        }
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
        value = local.output_resend[each.key].api_key
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

        password_recipe {
          length  = 64
          symbols = false
        }
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
        value = local.output_tailscale[each.key].tailnet_key
      }
    }
  }
}
