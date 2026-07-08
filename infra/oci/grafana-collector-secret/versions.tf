terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  cloud {
    organization = "litomi"

    workspaces {
      project = "oci"
      name    = "oci-grafana-collector-secret"
    }
  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.0"
    }
  }
}
