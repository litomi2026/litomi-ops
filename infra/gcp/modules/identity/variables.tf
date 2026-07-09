variable "project_id" {
  description = "Target GCP project id."
  type        = string
  nullable    = false
}

variable "project_number" {
  description = "Target GCP project number (used to build WIF principalSet members)."
  type        = string
  nullable    = false
}

variable "hcp_organization" {
  description = "HCP Terraform organization name allowed to federate (OIDC attribute condition)."
  type        = string
  default     = "litomi"
  nullable    = false
}

variable "workload_identity_pool_id" {
  description = "Workload Identity pool id for this project's HCP Terraform GCP workspaces."
  type        = string
  default     = "hcp-terraform"
  nullable    = false
}

variable "workload_identity_provider_id" {
  description = "OIDC provider id inside the pool."
  type        = string
  default     = "hcp-terraform"
  nullable    = false
}

variable "bootstrap_sa_id" {
  description = "Deployer SA the identity workspace runs as (privileged: IAM/WIF/SA admin)."
  type        = string
  default     = "tf-gcp-bootstrap"
  nullable    = false
}

variable "proxy_deployer_sa_id" {
  description = "Deployer SA the proxy workspace runs as (scoped: Cloud Run)."
  type        = string
  default     = "tf-gcp-proxy"
  nullable    = false
}

variable "bootstrap_workspace_name" {
  description = "HCP Terraform workspace name that may impersonate the bootstrap SA (WIF trust attribute)."
  type        = string
  nullable    = false
}

variable "proxy_workspace_name" {
  description = "HCP Terraform workspace name that may impersonate the proxy deployer SA (WIF trust attribute)."
  type        = string
  nullable    = false
}
