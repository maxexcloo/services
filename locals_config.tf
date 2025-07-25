locals {
  config_homepage = merge(
    {
      for k, server in local.output_servers : "1 - ${k} (${server.title})" => merge([
        for service in local.services_merged_outputs : {
          for widget in service.widgets : "${widget.priority != 0 ? widget.priority : can(widget.widget.type) ? "2" : "3"} - ${templatestring(widget.title, { default = var.default, server = server, service = service })}" => jsondecode(templatestring(jsonencode({
            description = widget.description
            href        = widget.enable_href ? widget.url : null
            icon        = widget.icon
            siteMonitor = widget.enable_monitoring ? widget.url : null
            widget      = widget.widget
          }), { default = var.default, server = server, service = service }))
          if widget.filter_exclude_server_flag == "" && widget.filter_include_server_flag == "" || widget.filter_exclude_server_flag != "" && contains(server.flags, widget.filter_exclude_server_flag) == false || contains(server.flags, widget.filter_include_server_flag)
        }
        if service.server == k
      ]...)
      if contains(server.flags, "homepage")
    },
    {
      "2 - Cloud" = merge([
        for service in local.services_merged_outputs : {
          for widget in service.widgets : "${widget.priority != 0 ? widget.priority : can(widget.widget.type) ? "2" : "3"} - ${templatestring(widget.title, { default = var.default, service = service })}${service.platform == "cloud" ? "" : " (${title(service.platform)})"}" => jsondecode(templatestring(jsonencode({
            description = widget.description
            href        = widget.enable_href ? widget.url : null
            icon        = widget.icon
            siteMonitor = widget.enable_monitoring ? widget.url : null
            widget      = widget.widget
          }), { default = var.default, service = service }))
        }
        if service.server == null
      ]...)
    }
  )

  config_outputs = merge(
    {
      for k, service in local.services_merged : k => {
        "/app/config.yaml" = templatefile(
          "templates/${service.service}/config.yaml",
          merge(local.config_template_vars[k], { gatus = service })
        )
      }
      if service.service == "gatus"
    },
    {
      for k, service in local.services_merged : k => {
        "/app/config/bookmarks.yaml"  = ""
        "/app/config/docker.yaml"     = ""
        "/app/config/kubernetes.yaml" = ""
        "/app/config/services.yaml"   = templatefile("templates/${service.service}/services.yaml", merge(local.config_template_vars[k], { services = local.config_homepage }))
        "/app/config/settings.yaml"   = templatefile("templates/${service.service}/settings.yaml", merge(local.config_template_vars[k], { homepage = service, services = local.config_homepage }))
        "/app/config/widgets.yaml"    = ""
      }
      if service.service == "homepage"
    },
    {
      for k, service in local.services_merged : k => {
        "/config/finger.json" = templatefile("templates/${service.service}/finger.json", local.config_template_vars[k])
      }
      if service.service == "www"
    },
  )

  config_template_vars = {
    for k, service in local.services_merged_outputs : k => {
      default   = var.default
      server    = try(local.output_servers[service.server], {})
      service   = service
      servers   = local.output_servers
      services  = local.services_merged
      tags      = var.tags
      terraform = var.terraform
    }
  }
}
