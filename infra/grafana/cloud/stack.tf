data "grafana_cloud_organization" "current" {
  slug = var.grafana_cloud_organization_slug
}

# The stack already exists and hosts every platform-provisioned app (Asserts,
# Synthetic Monitoring, k6, integrations-kubernetes). It is adopted via import so
# Terraform never recreates it — recreating would rotate every ingest endpoint URL
# that k8s/platform/grafana-k8s-monitoring pins.
import {
  to = grafana_cloud_stack.this
  id = var.grafana_stack_id
}

resource "grafana_cloud_stack" "this" {
  name        = var.grafana_stack_slug
  slug        = var.grafana_stack_slug
  region_slug = var.grafana_cloud_region
}
