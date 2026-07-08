# One-time adoption of the hand-seeded root of trust (see README "Bootstrap").
# These four resources must pre-exist before the gcp-project workspace can
# authenticate, so they are created by hand once and adopted here — a duplicate
# `create` on them errors, unlike the additive IAM members which adopt on apply.
#
# Delete this file in a follow-up commit after the first successful apply.

import {
  to = google_iam_workload_identity_pool.hcp
  id = "projects/${var.project_id}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}"
}

import {
  to = google_iam_workload_identity_pool_provider.hcp
  id = "projects/${var.project_id}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/providers/${var.workload_identity_provider_id}"
}

import {
  to = google_service_account.bootstrap
  id = "projects/${var.project_id}/serviceAccounts/${var.bootstrap_sa_id}@${var.project_id}.iam.gserviceaccount.com"
}

import {
  to = google_service_account.proxy_deployer
  id = "projects/${var.project_id}/serviceAccounts/${var.proxy_deployer_sa_id}@${var.project_id}.iam.gserviceaccount.com"
}
