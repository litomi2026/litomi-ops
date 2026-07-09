# Auth via HCP Terraform dynamic credentials, impersonating the tf-gcp-proxy SA
# (TFC_GCP_* workspace env vars). No key. See README "Provider Authentication".
# Every resource sets its own location, so the provider needs no default region.
provider "google" {
  project = var.project_id
}
