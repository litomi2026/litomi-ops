data "grafana_cloud_organization" "current" {
  slug = var.grafana_cloud_organization_slug
}

resource "grafana_cloud_stack" "this" {
  name        = var.grafana_stack_slug
  slug        = var.grafana_stack_slug
  region_slug = var.grafana_cloud_region
}
