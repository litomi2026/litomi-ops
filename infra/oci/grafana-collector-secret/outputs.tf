output "grafana_collector_secret_id" {
  description = "OCID of the Grafana Cloud collector Vault secret."
  value       = oci_vault_secret.grafana_collector.id
}
