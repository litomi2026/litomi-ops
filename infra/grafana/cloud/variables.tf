variable "grafana_cloud_access_policy_token" {
  description = "Grafana Cloud access policy token used to manage org-scope resources (stack, access policies, stack service accounts)."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "grafana_cloud_organization_slug" {
  description = "Grafana Cloud organization slug that owns the stack."
  type        = string
  nullable    = false
}

variable "grafana_cloud_region" {
  description = "Grafana Cloud region slug for the stack and access policies. Must match the region the existing stack was created in."
  type        = string
  default     = "prod-ap-northeast-0"
  nullable    = false
}

variable "grafana_stack_slug" {
  description = "Subdomain (slug) of the existing Grafana Cloud stack, e.g. the value in https://<slug>.grafana.net."
  type        = string
  nullable    = false
}

variable "grafana_stack_id" {
  description = "Numeric ID of the existing Grafana Cloud stack, used as the import identifier."
  type        = string
  nullable    = false
}

variable "frontend_o11y_app_name" {
  description = "Frontend Observability (Faro) app name."
  type        = string
  default     = "litomi-web"
  nullable    = false
}

variable "frontend_o11y_allowed_origins" {
  description = "Allowed CORS origins for the Frontend Observability collector."
  type        = list(string)
  default     = ["https://litomi.cc"]
  nullable    = false
}
