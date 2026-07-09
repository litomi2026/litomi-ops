# Account 1 identity plane. Thin root over ../modules/identity; workspace gcp-project.
module "identity" {
  source = "../modules/identity"

  project_id     = var.project_id
  project_number = var.project_number

  bootstrap_workspace_name = "gcp-project"
  proxy_workspace_name     = "gcp-proxy"
}
