# Account 1 Cloud Run proxy (Tokyo, proxy.litomi.cc). Thin root over ../modules/proxy;
# workspace gcp-proxy. Region and custom_domain use the module defaults.
locals {
  # Immutable image pin, shared with every other proxy account so all stay in
  # lockstep on the same digest. Bumped by the litomi CI promotion PR.
  image_digest = jsondecode(file("${path.module}/../image.json")).digest
}

module "proxy" {
  source = "../modules/proxy"

  project_id     = var.project_id
  project_number = var.project_number
  image_digest   = local.image_digest

  otel_exporter_otlp_endpoint = var.otel_exporter_otlp_endpoint
  otel_exporter_otlp_headers  = var.otel_exporter_otlp_headers
}

# Address-only moves from the pre-module layout. Safe to delete after the first apply.
moved {
  from = google_project_service.run
  to   = module.proxy.google_project_service.run
}

moved {
  from = google_project_service.artifactregistry
  to   = module.proxy.google_project_service.artifactregistry
}

moved {
  from = google_artifact_registry_repository.ghcr
  to   = module.proxy.google_artifact_registry_repository.ghcr
}

moved {
  from = google_artifact_registry_repository_iam_member.run_agent_reader
  to   = module.proxy.google_artifact_registry_repository_iam_member.run_agent_reader
}

moved {
  from = google_service_account.runtime
  to   = module.proxy.google_service_account.runtime
}

moved {
  from = google_cloud_run_v2_service.proxy
  to   = module.proxy.google_cloud_run_v2_service.proxy
}

moved {
  from = google_cloud_run_v2_service_iam_member.public_invoker
  to   = module.proxy.google_cloud_run_v2_service_iam_member.public_invoker
}

moved {
  from = google_cloud_run_domain_mapping.proxy
  to   = module.proxy.google_cloud_run_domain_mapping.proxy
}
