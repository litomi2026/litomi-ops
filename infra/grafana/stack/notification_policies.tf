# Always-on mute used to suppress non-actionable routes (24h every day).
resource "grafana_mute_timing" "always" {
  name = "always"

  intervals {
    times {
      start = "00:00"
      end   = "24:00"
    }
  }
}

# Root routing tree. Page only on actionable severities:
#   critical -> critical channel, warning (and unmatched) -> warning channel,
#   info     -> suppressed (the chatty Kubernetes integration signals live here).
resource "grafana_notification_policy" "root" {
  group_by      = ["grafana_folder", "alertname"]
  contact_point = grafana_contact_point.discord_warning.name

  group_wait      = "30s"
  group_interval  = "5m"
  repeat_interval = "4h"

  policy {
    contact_point = grafana_contact_point.discord_critical.name

    matcher {
      label = "severity"
      match = "="
      value = "critical"
    }
  }

  policy {
    contact_point = grafana_contact_point.discord_warning.name
    mute_timings   = [grafana_mute_timing.always.name]

    matcher {
      label = "severity"
      match = "="
      value = "info"
    }
  }
}
