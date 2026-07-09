variable "project_id" {
  description = "Account 1 GCP project id. Set as a gcp-proxy workspace variable (kept out of this public repo)."
  type        = string
  nullable    = false
}

variable "project_number" {
  description = "Account 1 GCP project number. Set as a gcp-proxy workspace variable (kept out of this public repo)."
  type        = string
  nullable    = false
}

variable "otel_exporter_otlp_endpoint" {
  description = "OTLP/HTTP traces endpoint (Grafana Cloud OTLP gateway). Sensitive — set as a gcp-proxy workspace variable, never in git."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "otel_exporter_otlp_headers" {
  description = "OTLP auth header. Sensitive — set as a gcp-proxy workspace variable, never in git."
  type        = string
  sensitive   = true
  nullable    = false
}
