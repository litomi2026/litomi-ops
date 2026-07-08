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

variable "region" {
  description = "Default provider region."
  type        = string
  default     = "asia-northeast3"
  nullable    = false
}

variable "hcp_organization" {
  description = "HCP Terraform organization name allowed to federate (OIDC attribute condition)."
  type        = string
  default     = "litomi"
  nullable    = false
}

variable "workload_identity_pool_id" {
  description = "Workload Identity pool id shared by all HCP Terraform GCP workspaces."
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
  description = "Deployer SA the gcp-project workspace runs as (privileged: IAM/WIF/SA admin)."
  type        = string
  default     = "tf-gcp-bootstrap"
  nullable    = false
}

variable "proxy_deployer_sa_id" {
  description = "Deployer SA the gcp-proxy workspace runs as (scoped: Cloud Run)."
  type        = string
  default     = "tf-gcp-proxy"
  nullable    = false
}
