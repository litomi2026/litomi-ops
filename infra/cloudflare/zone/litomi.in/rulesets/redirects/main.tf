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

variable "domain" {
  description = "Primary Cloudflare zone name."
  type        = string
  default     = "litomi.in"
  nullable    = false
}

locals {
  adult_access_cookie = "__Secure-adult-pass=1"

  adult_gate_api_proxy_condition         = "(starts_with(http.request.uri.path, \"/api/proxy/\"))"
  adult_gate_image_proxy_condition       = "(starts_with(http.request.uri.path, \"/i/\"))"
  adult_gate_protected_content_condition = "(${local.adult_gate_api_proxy_condition} or ${local.adult_gate_image_proxy_condition})"

  adult_gate_kr_deterrence_condition = join(" and ", [
    local.adult_gate_protected_content_condition,
    "(ip.src.country eq \"KR\")",
    "(not http.cookie contains \"${local.adult_access_cookie}\")",
  ])
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
    },
    {
      ref    = "adult_gate_kr_deterrence"
      action = "redirect"
      action_parameters = {
        from_value = {
          status_code = 302
          target_url = {
            value = "https://${var.domain}/deterrence"
          }
          preserve_query_string = false
        }
      }
      expression  = local.adult_gate_kr_deterrence_condition
      description = "Redirect Korean adult-gated API/image traffic to deterrence when adult pass cookie is missing"
      # Enable after the app starts issuing the adult access cookie.
      enabled = false
    }
  ]
}
