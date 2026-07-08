output "service_uri" {
  description = "Cloud Run proxy run.app URI. Target host for the Cloudflare Origin Rule."
  value       = google_cloud_run_v2_service.proxy.uri
}

output "service_name" {
  description = "Cloud Run service name."
  value       = google_cloud_run_v2_service.proxy.name
}

output "runtime_service_account" {
  description = "Runtime service account the proxy executes as."
  value       = google_service_account.runtime.email
}
