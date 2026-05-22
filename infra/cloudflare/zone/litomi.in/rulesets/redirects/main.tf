terraform {
  cloud {
    organization = "litomi"

    workspaces {
      project = "cloudflare"
      name    = "litomi-cloudflare-zone-litomi-in-rulesets-redirects"
    }
  }

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

variable "domain" {
  description = "Primary Cloudflare zone name."
  type        = string
  default     = "litomi.in"
  nullable    = false
}

resource "cloudflare_ruleset" "www_redirect" {
  zone_id     = var.zone_id
  name        = "WWW Redirect"
  description = "Redirect www to root"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [
    {
      action = "redirect"
      action_parameters = {
        from_value = {
          status_code = 301
          target_url = {
            expression = "concat(\"https://${var.domain}\", http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
      expression  = "http.host eq \"www.${var.domain}\""
      description = "Redirect www to root"
      enabled     = true
    }
  ]
}
