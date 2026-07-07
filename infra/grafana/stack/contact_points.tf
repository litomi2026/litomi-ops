resource "grafana_contact_point" "discord" {
  name = "discord"

  discord {
    url                     = var.discord_webhook_url
    disable_resolve_message = false
  }
}
