terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.16.0, < 6.0.0"
    }
  }
}

provider "cloudflare" {}

variable "zone_id" {
  description = "Cloudflare zone ID for litomi.in."
  type        = string
  nullable    = false
}

resource "cloudflare_managed_transforms" "managed_transforms" {
  zone_id = var.zone_id

  managed_request_headers = [
    {
      id      = "add_visitor_location_headers"
      enabled = true
    },
  ]

  managed_response_headers = [
    {
      id      = "remove_x-powered-by_header"
      enabled = true
    },
  ]
}
