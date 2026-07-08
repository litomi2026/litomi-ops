variable "project_id" {
  description = "GCP project that hosts the Cloud Run proxy."
  type        = string
  nullable    = false
}

variable "project_number" {
  description = "GCP project number, used to grant the Cloud Run service agent read on the pull-through cache."
  type        = string
  nullable    = false
}

variable "region" {
  description = "Cloud Run region. Must be a region that supports domain mappings (asia-northeast3/Seoul does NOT; asia-northeast1/Tokyo does). VPC-unconnected so egress rotates across Google's dynamic IP pool."
  type        = string
  default     = "asia-northeast1"
  nullable    = false
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
  default     = "litomi-proxy"
  nullable    = false
}

variable "custom_domain" {
  description = "Custom domain mapped to the service. Cloudflare fronts it (proxied CNAME to ghs.googlehosted.com); the mapping makes Cloud Run accept this Host and serve a matching Google-managed cert."
  type        = string
  default     = "proxy.litomi.cc"
  nullable    = false
}

variable "remote_repository_id" {
  description = "Artifact Registry remote repository (pull-through cache for GHCR). Cloud Run cannot pull ghcr.io directly."
  type        = string
  default     = "ghcr"
  nullable    = false
}

variable "upstream_image" {
  description = "GHCR image path without the ghcr.io host. Must be a public package so the cache can fetch it without upstream auth."
  type        = string
  default     = "litomi2026/litomi-proxy"
  nullable    = false
}

variable "cache_keep_count" {
  description = "Most-recent cached image versions the cleanup policy retains; older ones are evicted (re-fetchable from GHCR). Keeps the remote cache within the Artifact Registry 0.5 GB free tier."
  type        = number
  default     = 3
  nullable    = false
}

variable "app_origin" {
  description = "Public site origin passed to the proxy as NEXT_PUBLIC_APP_ORIGIN."
  type        = string
  default     = "https://litomi.cc"
  nullable    = false
}

variable "max_instances" {
  description = "Autoscaling upper bound. Min stays 0 (Bun cold start is fast)."
  type        = number
  default     = 10
  nullable    = false
}

variable "request_concurrency" {
  description = "Max concurrent requests per instance."
  type        = number
  default     = 200
  nullable    = false
}

variable "request_timeout" {
  description = "Per-request timeout (duration string, e.g. \"20s\")."
  type        = string
  default     = "20s"
  nullable    = false
}

variable "cpu_limit" {
  description = "Per-instance CPU limit."
  type        = string
  default     = "1"
  nullable    = false
}

variable "memory_limit" {
  description = "Per-instance memory limit."
  type        = string
  default     = "512Mi"
  nullable    = false
}

variable "allow_unauthenticated" {
  description = "Grant allUsers roles/run.invoker so Cloudflare can reach the service publicly (same exposure as the prior Vercel deployment)."
  type        = bool
  default     = true
  nullable    = false
}
