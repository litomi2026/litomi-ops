output "workload_identity_provider_name" {
  description = "Full WIF provider resource name. Set as TFC_GCP_WORKLOAD_PROVIDER_NAME on every account-1 GCP workspace."
  value       = module.identity.workload_identity_provider_name
}

output "bootstrap_service_account" {
  description = "Deployer SA for the gcp-project workspace (TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL there)."
  value       = module.identity.bootstrap_service_account
}

output "proxy_deployer_service_account" {
  description = "Deployer SA for the gcp-proxy workspace (TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL there)."
  value       = module.identity.proxy_deployer_service_account
}
