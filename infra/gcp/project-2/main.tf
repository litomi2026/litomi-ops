# Account 2 identity plane. Thin root over ../modules/identity; workspace gcp-project-2.
# Account 2 is a separate Google account with its own WIF pool and deployer SAs.
module "identity" {
  source = "../modules/identity"

  project_id     = var.project_id
  project_number = var.project_number

  bootstrap_workspace_name = "gcp-project-2"
  proxy_workspace_name     = "gcp-proxy-2"
}
