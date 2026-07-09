# Auth via HCP Terraform dynamic credentials, impersonating account 2's
# tf-gcp-bootstrap SA (TFC_GCP_* workspace env vars). No key.
# Identity resources are project-global, so the provider needs no default region.
provider "google" {
  project = var.project_id
}
