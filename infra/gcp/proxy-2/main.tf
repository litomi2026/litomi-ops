# Account 2 Cloud Run proxy (Taiwan, proxy2.litomi.cc). Thin root over ../modules/proxy;
# workspace gcp-proxy-2. A separate GCP account + region gives an independent egress
# IP pool, so the app can spread source traffic across both proxies.
locals {
  # Same shared digest as account 1 — every proxy account stays in lockstep.
  image_digest = jsondecode(file("${path.module}/../image.json")).digest
}

module "proxy" {
  source = "../modules/proxy"

  project_id     = var.project_id
  project_number = var.project_number
  image_digest   = local.image_digest

  region        = "asia-east1"
  custom_domain = "proxy2.litomi.cc"

  otel_exporter_otlp_endpoint = var.otel_exporter_otlp_endpoint
  otel_exporter_otlp_headers  = var.otel_exporter_otlp_headers
}
