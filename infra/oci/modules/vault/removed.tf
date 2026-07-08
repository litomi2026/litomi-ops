# Transitional: forget the Grafana collector secret from state without destroying
# it, so oci-grafana-collector-secret can adopt the same OCI secret via import.
# Delete this file after the apply that processes it.
removed {
  from = oci_vault_secret.grafana_k8s_monitoring

  lifecycle {
    destroy = false
  }
}
