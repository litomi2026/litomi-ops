terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  cloud {
    organization = "litomi"

    workspaces {
      project = "gcp"
      name    = "gcp-project"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
