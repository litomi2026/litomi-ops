# Bootstrap / identity plane for the `gcp` project. Owns the HCP Terraform trust
# (WIF pool + provider), the per-workspace deployer SAs, and their project IAM.
# The scoped app workspaces (e.g. gcp-proxy) only own their own workloads.
#
# Self-lockout guard: this workspace runs AS `tf-gcp-bootstrap`, which it also
# manages. The root-of-trust resources (pool, provider, bootstrap SA, and its
# impersonation binding) carry `prevent_destroy` so a bad plan can't revoke this
# workspace's own access. Additive IAM members recover by re-apply, so they don't.

locals {
  wif_pool_principal = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}"
}

# --- Identity-plane APIs ---
resource "google_project_service" "identity" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- Workload Identity Federation: trust HCP Terraform's OIDC issuer ---
resource "google_iam_workload_identity_pool" "hcp" {
  project                   = var.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "HCP Terraform"
  description               = "OIDC federation for HCP Terraform workspaces"

  depends_on = [google_project_service.identity]

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_iam_workload_identity_pool_provider" "hcp" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.hcp.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_provider_id
  display_name                       = "HCP Terraform"

  attribute_mapping = {
    "google.subject"                        = "assertion.sub"
    "attribute.terraform_workspace_name"    = "assertion.terraform_workspace_name"
    "attribute.terraform_organization_name" = "assertion.terraform_organization_name"
  }

  # Only tokens minted for this HCP organization are accepted; per-SA bindings
  # below scope which workspace may impersonate which deployer SA.
  attribute_condition = "assertion.terraform_organization_name == \"${var.hcp_organization}\""

  oidc {
    issuer_uri = "https://app.terraform.io"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# --- Bootstrap SA: identity the gcp-project workspace runs as (privileged) ---
resource "google_service_account" "bootstrap" {
  project      = var.project_id
  account_id   = var.bootstrap_sa_id
  display_name = "HCP Terraform gcp-project bootstrap"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_iam_member" "bootstrap" {
  for_each = toset([
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/serviceusage.serviceUsageAdmin",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.bootstrap.email}"
}

resource "google_service_account_iam_member" "bootstrap_wif" {
  service_account_id = google_service_account.bootstrap.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.wif_pool_principal}/attribute.terraform_workspace_name/gcp-project"

  lifecycle {
    prevent_destroy = true
  }
}

# --- Proxy deployer SA: identity the gcp-proxy workspace runs as (scoped) ---
resource "google_service_account" "proxy_deployer" {
  project      = var.project_id
  account_id   = var.proxy_deployer_sa_id
  display_name = "HCP Terraform gcp-proxy deployer"
}

resource "google_project_iam_member" "proxy_deployer" {
  for_each = toset([
    "roles/run.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/artifactregistry.admin",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.proxy_deployer.email}"
}

resource "google_service_account_iam_member" "proxy_deployer_wif" {
  service_account_id = google_service_account.proxy_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.wif_pool_principal}/attribute.terraform_workspace_name/gcp-proxy"
}
