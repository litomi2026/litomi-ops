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
