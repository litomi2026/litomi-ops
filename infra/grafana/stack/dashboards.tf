# Custom dashboards are files under ./dashboards/*.json. Drop a dashboard's JSON
# model there and it is managed here — one control plane with the rest of infra.
resource "grafana_dashboard" "litomi" {
  for_each = fileset("${path.module}/dashboards", "*.json")

  folder      = grafana_folder.litomi.uid
  config_json = file("${path.module}/dashboards/${each.value}")
}
