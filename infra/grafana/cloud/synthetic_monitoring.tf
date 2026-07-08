# Dedicated publisher token for Synthetic Monitoring (needs stacks:read + write).
resource "grafana_cloud_access_policy" "sm_publisher" {
  region       = var.grafana_cloud_region
  name         = "litomi-prod-sm-publisher"
  display_name = "Litomi prod Synthetic Monitoring publisher"

  scopes = [
    "stacks:read",
    "metrics:write",
    "logs:write",
    "traces:write",
  ]

  realm {
    type       = "stack"
    identifier = grafana_cloud_stack.this.id
  }
}

resource "grafana_cloud_access_policy_token" "sm_publisher" {
  region           = var.grafana_cloud_region
  access_policy_id = grafana_cloud_access_policy.sm_publisher.policy_id
  name             = "litomi-prod-sm-publisher"
  display_name     = "Litomi prod Synthetic Monitoring publisher"
}

# SM is already enabled; this resource cannot be imported but applies cleanly on
# an existing installation and yields the SM API token used by the grafana.sm provider.
resource "grafana_synthetic_monitoring_installation" "this" {
  stack_id              = grafana_cloud_stack.this.id
  metrics_publisher_key = grafana_cloud_access_policy_token.sm_publisher.token
}

data "grafana_synthetic_monitoring_probes" "main" {
  provider   = grafana.sm
  depends_on = [grafana_synthetic_monitoring_installation.this]
}

resource "grafana_synthetic_monitoring_check" "web_health" {
  provider = grafana.sm

  job     = "litomi-prod-web-health"
  target  = "https://litomi.cc/health"
  enabled = true
  probes  = [data.grafana_synthetic_monitoring_probes.main.probes.Tokyo]

  labels = {
    component = "web"
    env       = "prod"
    service   = "litomi-web"
  }

  settings {
    http {}
  }
}

resource "grafana_synthetic_monitoring_check" "api_health" {
  provider = grafana.sm

  job     = "litomi-prod-api-health"
  target  = "https://litomi.cc/api/health"
  enabled = true
  probes  = [data.grafana_synthetic_monitoring_probes.main.probes.Tokyo]

  labels = {
    component = "api"
    env       = "prod"
    service   = "litomi-api"
  }

  settings {
    http {}
  }
}
