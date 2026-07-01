terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  cloud {
    organization = "litomi"

    workspaces {
      project = "aiven"
      name    = "aiven-prod"
    }
  }

  required_providers {
    aiven = {
      source  = "aiven/aiven"
      version = "~> 4.0"
    }
  }
}
