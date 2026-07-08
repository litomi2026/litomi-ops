# Frontend Observability (Faro) app registration. The browser SDK ships to the
# exported collector_endpoint. This resource cannot be cleanly imported, so
# adopting it points the web app's Faro config at this app's collector_endpoint.
resource "grafana_frontend_o11y_app" "litomi" {
  stack_id        = grafana_cloud_stack.this.id
  name            = var.frontend_o11y_app_name
  allowed_origins = var.frontend_o11y_allowed_origins

  extra_log_attributes = {
    service = var.frontend_o11y_app_name
  }

  settings = {
    "geolocation.enabled" = "0"
  }
}
