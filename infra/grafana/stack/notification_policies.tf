# Owns the root Alertmanager routing tree. Default (incl. unlabeled and critical)
# goes to the critical channel — fail-loud — and severity=warning splits off to the
# warning channel. Replaces the previous empty root receiver that dropped alerts.
resource "grafana_notification_policy" "root" {
  group_by      = ["grafana_folder", "alertname"]
  contact_point = grafana_contact_point.discord_critical.name

  group_wait      = "30s"
  group_interval  = "5m"
  repeat_interval = "4h"

  policy {
    contact_point = grafana_contact_point.discord_warning.name

    matcher {
      label = "severity"
      match = "="
      value = "warning"
    }
  }
}
