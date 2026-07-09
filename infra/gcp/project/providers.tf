# Auth via HCP Terraform dynamic credentials, impersonating the tf-gcp-bootstrap
# SA (TFC_GCP_* workspace env vars). No key. See README "Provider Authentication".
# Identity resources are project-global, so the provider needs no default region.
provider "google" {
  project = var.project_id
}
