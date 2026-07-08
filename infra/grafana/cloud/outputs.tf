output "stack_url" {
  description = "Grafana stack root URL, consumed by grafana-stack-prod for the in-stack provider."
  value       = grafana_cloud_stack.this.url
}

output "stack_slug" {
  description = "Grafana stack slug."
  value       = grafana_cloud_stack.this.slug
}

output "stack_service_account_token" {
  description = "Admin service account token consumed by grafana-stack-prod for the in-stack provider."
  value       = grafana_cloud_stack_service_account_token.terraform.key
  sensitive   = true
}

output "frontend_o11y_collector_endpoint" {
  description = "Faro collector URL for the browser SDK. Point the web app's Faro config here."
  value       = grafana_frontend_o11y_app.litomi.collector_endpoint
}

# Consumed by the oci-grafana-collector-secret workspace, which writes it to OCI
# Vault. Per-signal username is the stack ingest user id; password is the shared
# write token. Rotating the token is a grafana-cloud apply followed by that workspace.
output "collector_credentials" {
  description = "grafana-k8s-monitoring collector basic-auth credentials for OCI Vault delivery."
  sensitive   = true
  value = {
    GRAFANA_CLOUD_METRICS_USERNAME  = grafana_cloud_stack.this.prometheus_user_id
    GRAFANA_CLOUD_METRICS_PASSWORD  = grafana_cloud_access_policy_token.collector_write.token
    GRAFANA_CLOUD_LOGS_USERNAME     = grafana_cloud_stack.this.logs_user_id
    GRAFANA_CLOUD_LOGS_PASSWORD     = grafana_cloud_access_policy_token.collector_write.token
    GRAFANA_CLOUD_PROFILES_USERNAME = grafana_cloud_stack.this.profiles_user_id
    GRAFANA_CLOUD_PROFILES_PASSWORD = grafana_cloud_access_policy_token.collector_write.token
  }
}
