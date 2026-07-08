# ⚠️ This proxy exists for egress IP rotation. Do NOT attach a Serverless VPC
#    Connector, Direct VPC egress, or Cloud NAT — the moment egress is pinned to a
#    static IP the manga sources (hiyobi / k-hentai / …) block it. VPC-unconnected
#    (the default) = Google's dynamic IP pool = rotation, matching the prior Vercel edge.

resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Cloud Run can only pull from gcr.io / *-docker.pkg.dev / docker.io — NOT ghcr.io.
# This Artifact Registry remote repository is a pull-through cache for the public
# GHCR package, so CI keeps pushing only to GHCR (zero GCP credentials in CI) and
# Cloud Run pulls the same immutable digest via Artifact Registry.
resource "google_artifact_registry_repository" "ghcr" {
  project       = var.project_id
  location      = var.region
  repository_id = var.remote_repository_id
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"

  remote_repository_config {
    description = "Pull-through cache for ghcr.io/${var.upstream_image}"

    docker_repository {
      custom_repository {
        uri = "https://ghcr.io"
      }
    }
  }

  depends_on = [google_project_service.artifactregistry]
}

# The Cloud Run service agent pulls the image; grant it read on the cache repo.
resource "google_artifact_registry_repository_iam_member" "run_agent_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.ghcr.location
  repository = google_artifact_registry_repository.ghcr.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${var.project_number}@serverless-robot-prod.iam.gserviceaccount.com"
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
  # Pulled through the Artifact Registry cache, not ghcr.io directly.
  image_digest = jsondecode(file("${path.module}/image.json")).digest
  image        = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ghcr.repository_id}/${var.upstream_image}@${local.image_digest}"
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

  depends_on = [
    google_project_service.run,
    google_artifact_registry_repository_iam_member.run_agent_reader,
  ]
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
