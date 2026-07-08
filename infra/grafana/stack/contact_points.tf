resource "grafana_contact_point" "discord_critical" {
  name = "discord-critical-alerts"

  discord {
    url                     = var.discord_critical_webhook_url
    disable_resolve_message = false
  }
}

resource "grafana_contact_point" "discord_warning" {
  name = "discord-warning-alerts"

  discord {
    url                     = var.discord_warning_webhook_url
    disable_resolve_message = false
  }
}
