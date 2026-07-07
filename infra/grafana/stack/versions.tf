terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  cloud {
    organization = "litomi"

    workspaces {
      project = "grafana"
      name    = "grafana-stack-prod"
    }
  }

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 4.40.0, < 5.0.0"
    }
  }
}
