# Account 1 identity plane. Thin root over ../modules/identity; workspace gcp-project.
module "identity" {
  source = "../modules/identity"

  project_id     = var.project_id
  project_number = var.project_number

  bootstrap_workspace_name = "gcp-project"
  proxy_workspace_name     = "gcp-proxy"
}

# Address-only moves from the pre-module layout. Safe to delete after the first apply.
moved {
  from = google_project_service.identity
  to   = module.identity.google_project_service.identity
}

moved {
  from = google_iam_workload_identity_pool.hcp
  to   = module.identity.google_iam_workload_identity_pool.hcp
}

moved {
  from = google_iam_workload_identity_pool_provider.hcp
  to   = module.identity.google_iam_workload_identity_pool_provider.hcp
}

moved {
  from = google_service_account.bootstrap
  to   = module.identity.google_service_account.bootstrap
}

moved {
  from = google_project_iam_member.bootstrap
  to   = module.identity.google_project_iam_member.bootstrap
}

moved {
  from = google_service_account_iam_member.bootstrap_wif
  to   = module.identity.google_service_account_iam_member.bootstrap_wif
}

moved {
  from = google_service_account.proxy_deployer
  to   = module.identity.google_service_account.proxy_deployer
}

moved {
  from = google_project_iam_member.proxy_deployer
  to   = module.identity.google_project_iam_member.proxy_deployer
}

moved {
  from = google_service_account_iam_member.proxy_deployer_wif
  to   = module.identity.google_service_account_iam_member.proxy_deployer_wif
}
