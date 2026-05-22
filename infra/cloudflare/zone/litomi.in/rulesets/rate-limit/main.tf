terraform {
  cloud {
    organization = "litomi"

    workspaces {
      project = "cloudflare"
      name    = "litomi-cloudflare-zone-litomi-in-rulesets-rate-limiting"
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

locals {
  rate_limit_period   = 10000
  rate_limit_requests = 10000
  rate_limit_timeout  = 10000
}

resource "cloudflare_ruleset" "rate_limiting" {
  zone_id = var.zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = [
    {
      ref         = "rate_limit"
      enabled     = true
      description = "Rate limit"
      expression  = "(starts_with(http.request.uri.path, \"/\") and not starts_with(http.request.uri.path, \"/cdn-cgi/challenge-platform/\") and not starts_with(http.request.uri.path, \"/.well-known/\") and not http.request.uri.path contains \".\")"
      action      = "block"

      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = local.rate_limit_period
        requests_per_period = local.rate_limit_requests
        mitigation_timeout  = local.rate_limit_timeout
      }
    }
  ]
}

output "rate_limiting_rules_count" {
  description = "Number of rate limiting rules configured."
  value       = length(cloudflare_ruleset.rate_limiting.rules)
}
