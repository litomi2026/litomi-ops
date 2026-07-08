variable "project_id" {
  description = "GCP project that hosts the Cloud Run proxy."
  type        = string
  nullable    = false
}

variable "region" {
  description = "Cloud Run region. The proxy stays VPC-unconnected so egress rotates across Google's dynamic IP pool."
  type        = string
  default     = "asia-northeast3"
  nullable    = false
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
  default     = "litomi-proxy"
  nullable    = false
}

variable "image_repository" {
  description = "GHCR image repository (without tag/digest). Must be a public package so Cloud Run can pull it without registry auth."
  type        = string
  default     = "ghcr.io/litomi2026/litomi-proxy"
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
