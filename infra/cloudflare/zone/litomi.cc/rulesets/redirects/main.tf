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

data "cloudflare_zone" "this" {
  filter = {
    name = var.domain
  }
}

variable "domain" {
  description = "Primary Cloudflare zone name."
  type        = string
  default     = "litomi.cc"
  nullable    = false
}

resource "cloudflare_ruleset" "www_redirect" {
  zone_id     = data.cloudflare_zone.this.zone_id
  name        = "Dynamic Redirects"
  description = "www→root and HTTPS enforcement"
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
    },
    {
      action = "redirect"
      action_parameters = {
        from_value = {
          status_code = 301
          target_url = {
            expression = "concat(\"https://\", http.host, http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
      # Replaces the "Always Use HTTPS" zone setting, but exempts the ACME HTTP-01
      # challenge path so the Cloud Run domain-mapping cert can renew over HTTP
      # through the (proxied) origin — required to stay valid under Full (Strict).
      expression  = "(not ssl) and (not starts_with(http.request.uri.path, \"/.well-known/acme-challenge/\"))"
      description = "Force HTTPS except ACME HTTP-01 challenge"
      enabled     = true
    }
  ]
}
