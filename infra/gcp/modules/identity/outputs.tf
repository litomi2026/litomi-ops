output "workload_identity_provider_name" {
  description = "Full WIF provider resource name. Set as TFC_GCP_WORKLOAD_PROVIDER_NAME on every GCP workspace in this project."
  value       = "projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.hcp.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.hcp.workload_identity_pool_provider_id}"
}

output "bootstrap_service_account" {
  description = "Deployer SA for the identity workspace (TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL there)."
  value       = google_service_account.bootstrap.email
}

output "proxy_deployer_service_account" {
  description = "Deployer SA for the proxy workspace (TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL there)."
  value       = google_service_account.proxy_deployer.email
}
