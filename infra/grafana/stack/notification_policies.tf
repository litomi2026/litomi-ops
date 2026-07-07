# Owns the root Alertmanager routing tree. Every alert routes to Discord by
# default — this is the resource whose empty receiver previously dropped alerts.
resource "grafana_notification_policy" "root" {
  group_by      = ["grafana_folder", "alertname"]
  contact_point = grafana_contact_point.discord.name

  group_wait      = "30s"
  group_interval  = "5m"
  repeat_interval = "4h"
}
