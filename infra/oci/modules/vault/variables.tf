variable "compartment_id" {
  description = "Target OCI compartment OCID."
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for named vault resources."
  type        = string
}

variable "web_secret_name" {
  description = "Vault secret name used by the web workload."
  type        = string
}

variable "api_secret_name" {
  description = "Vault secret name used by the API workload."
  type        = string
}

variable "cataloger_secret_name" {
  description = "Vault secret name used by the cataloger workload."
  type        = string
}

variable "notifier_secret_name" {
  description = "Vault secret name used by the notifier workload."
  type        = string
}

variable "chat_secret_name" {
  description = "Vault secret name used by the chat workload."
  type        = string
}

variable "argocd_secret_name" {
  description = "Vault secret name used by Argo CD."
  type        = string
}

variable "cert_manager_secret_name" {
  description = "Vault secret name used by cert-manager."
  type        = string
}

variable "grafana_k8s_monitoring_secret_name" {
  description = "Vault secret name used by Grafana Kubernetes Monitoring."
  type        = string
}

variable "freeform_tags" {
  description = "Freeform tags applied to vault resources."
  type        = map(string)
  default     = {}
}
