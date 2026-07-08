# Auth via HCP Terraform dynamic credentials, impersonating the tf-gcp-bootstrap
# SA (TFC_GCP_* workspace env vars). No key. See README "Provider Authentication".
provider "google" {
  project = var.project_id
  region  = var.region
}
