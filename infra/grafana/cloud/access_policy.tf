# Least-privilege write-only policy for the Alloy collectors that ship
# metrics / logs / traces / profiles from OKE to Grafana Cloud.
resource "grafana_cloud_access_policy" "collector_write" {
  region       = var.grafana_cloud_region
  name         = "litomi-prod-collector-write"
  display_name = "Litomi prod collector (write)"

  scopes = [
    "metrics:write",
    "logs:write",
    "traces:write",
    "profiles:write",
  ]

  realm {
    type       = "stack"
    identifier = grafana_cloud_stack.this.id
  }
}

resource "grafana_cloud_access_policy_token" "collector_write" {
  region           = var.grafana_cloud_region
  access_policy_id = grafana_cloud_access_policy.collector_write.policy_id
  name             = "litomi-prod-collector-write"
  display_name     = "Litomi prod collector (write)"
}
