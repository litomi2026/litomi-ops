# Provider auth is injected as the HCP Terraform workspace environment variable
# GOOGLE_CREDENTIALS (a service-account key JSON, sensitive) — never in code or
# local tfvars. See README "Provider Authentication".
provider "google" {
  project = var.project_id
  region  = var.region
}
