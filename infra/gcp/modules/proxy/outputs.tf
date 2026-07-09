output "service_uri" {
  description = "Cloud Run proxy run.app URI (direct origin; Cloudflare fronts the custom domain via the mapping, not this)."
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

output "domain_mapping_records" {
  description = "DNS records the custom domain must serve (subdomain → CNAME ghs.googlehosted.com). Set the matching proxied record in Cloudflare."
  value       = google_cloud_run_domain_mapping.proxy.status
}
