output "service_uri" {
  description = "Cloud Run proxy run.app URI (direct origin; Cloudflare fronts the custom domain via the mapping, not this)."
  value       = module.proxy.service_uri
}

output "service_name" {
  description = "Cloud Run service name."
  value       = module.proxy.service_name
}

output "runtime_service_account" {
  description = "Runtime service account the proxy executes as."
  value       = module.proxy.runtime_service_account
}

output "domain_mapping_records" {
  description = "DNS records the custom domain must serve (proxy2 → CNAME ghs.googlehosted.com). Set the matching proxied record in Cloudflare."
  value       = module.proxy.domain_mapping_records
}
