# ⚠️ This proxy exists for egress IP rotation. Do NOT attach a Serverless VPC
#    Connector, Direct VPC egress, or Cloud NAT — the moment egress is pinned to a
#    static IP the manga sources (hiyobi / k-hentai / …) block it. VPC-unconnected
#    (the default) = Google's dynamic IP pool = rotation, matching the prior Vercel edge.

resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Dedicated least-privilege runtime identity instead of the default compute SA.
# The proxy only makes outbound HTTP, so it is granted no roles.
resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "${var.service_name}-runtime"
  display_name = "litomi proxy Cloud Run runtime"
}

locals {
  # Immutable image pin. `image.json` is bumped by the litomi CI promotion PR
  # (`.digest`) and is a plain JSON file so it survives the *.tfvars .gitignore.
  image_digest = jsondecode(file("${path.module}/image.json")).digest
  image        = "${var.image_repository}@${local.image_digest}"
}

resource "google_cloud_run_v2_service" "proxy" {
  project             = var.project_id
  name                = var.service_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account                  = google_service_account.runtime.email
    max_instance_request_concurrency = var.request_concurrency
    timeout                          = var.request_timeout

    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    containers {
      image = local.image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "NEXT_PUBLIC_APP_ORIGIN"
        value = var.app_origin
      }
    }
  }

  depends_on = [google_project_service.run]
}

# Source proxy is called publicly from behind Cloudflare (same exposure as the
# prior Vercel deployment). If an org policy blocks allUsers, see README hardening.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = google_cloud_run_v2_service.proxy.location
  name     = google_cloud_run_v2_service.proxy.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
