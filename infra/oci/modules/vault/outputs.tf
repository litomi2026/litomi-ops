output "vault_id" {
  description = "Vault OCID."
  value       = oci_kms_vault.this.id
}

output "vault_management_endpoint" {
  description = "Vault management endpoint."
  value       = oci_kms_vault.this.management_endpoint
}

output "key_id" {
  description = "KMS key OCID."
  value       = oci_kms_key.this.id
}

output "web_secret_id" {
  description = "Web workload vault secret OCID."
  value       = oci_vault_secret.web.id
}

output "web_secret_name" {
  description = "Web secret name."
  value       = var.web_secret_name
}

output "api_secret_id" {
  description = "API workload vault secret OCID."
  value       = oci_vault_secret.api.id
}

output "api_secret_name" {
  description = "API secret name."
  value       = var.api_secret_name
}

output "cataloger_secret_id" {
  description = "Cataloger workload vault secret OCID."
  value       = oci_vault_secret.cataloger.id
}

output "cataloger_secret_name" {
  description = "Cataloger secret name."
  value       = var.cataloger_secret_name
}

output "notifier_secret_id" {
  description = "Notifier workload vault secret OCID."
  value       = oci_vault_secret.notifier.id
}

output "notifier_secret_name" {
  description = "Notifier secret name."
  value       = var.notifier_secret_name
}

output "recommender_secret_id" {
  description = "Recommender workload vault secret OCID."
  value       = oci_vault_secret.recommender.id
}

output "recommender_secret_name" {
  description = "Recommender secret name."
  value       = var.recommender_secret_name
}

output "chat_secret_id" {
  description = "Chat workload vault secret OCID."
  value       = oci_vault_secret.chat.id
}

output "chat_secret_name" {
  description = "Chat secret name."
  value       = var.chat_secret_name
}

output "chat_worker_secret_id" {
  description = "chat-worker workload vault secret OCID."
  value       = oci_vault_secret.chat_worker.id
}

output "chat_worker_secret_name" {
  description = "chat-worker secret name."
  value       = var.chat_worker_secret_name
}

output "chat_push_secret_id" {
  description = "chat-push workload vault secret OCID."
  value       = oci_vault_secret.chat_push.id
}

output "chat_push_secret_name" {
  description = "chat-push secret name."
  value       = var.chat_push_secret_name
}

output "argocd_secret_id" {
  description = "Argo CD vault secret OCID."
  value       = oci_vault_secret.argocd.id
}

output "argocd_secret_name" {
  description = "Argo CD secret name."
  value       = var.argocd_secret_name
}

output "cert_manager_secret_id" {
  description = "cert-manager vault secret OCID."
  value       = oci_vault_secret.cert_manager.id
}

output "cert_manager_secret_name" {
  description = "cert-manager secret name."
  value       = var.cert_manager_secret_name
}
