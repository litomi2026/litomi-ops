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
