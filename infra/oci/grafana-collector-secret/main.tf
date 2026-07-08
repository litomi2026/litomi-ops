# Delivers the Grafana Cloud collector credential into OCI Vault, where the
# grafana-k8s-monitoring ExternalSecret reads it. Content comes from the
# grafana-cloud workspace; this workspace never holds Grafana credentials.
resource "oci_vault_secret" "grafana_collector" {
  compartment_id = var.compartment_id
  vault_id       = var.vault_ocid
  key_id         = var.kms_key_ocid
  secret_name    = var.grafana_collector_secret_name
  description    = "Grafana Cloud collector credentials for grafana-k8s-monitoring. Content sourced from the grafana-cloud workspace."
  freeform_tags  = var.freeform_tags

  secret_content {
    content_type = "BASE64"
    content      = base64encode(jsonencode(data.terraform_remote_state.grafana_cloud.outputs.collector_credentials))
    name         = "grafana-cloud-collector"
    stage        = "CURRENT"
  }
}
