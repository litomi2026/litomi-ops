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
  description = "Cloudflare zone ID for litomi.cc."
  type        = string
  nullable    = false
}

variable "rate_limit_period" {
  description = "Rate limiting period in seconds."
  type        = number
  nullable    = false
  sensitive   = true
}

variable "rate_limit_requests" {
  description = "Maximum requests allowed per rate limiting period."
  type        = number
  nullable    = false
  sensitive   = true
}

variable "rate_limit_timeout" {
  description = "Mitigation timeout in seconds when the rate limit is exceeded."
  type        = number
  nullable    = false
  sensitive   = true
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
        period              = var.rate_limit_period
        requests_per_period = var.rate_limit_requests
        mitigation_timeout  = var.rate_limit_timeout
      }
    }
  ]
}

output "rate_limiting_rules_count" {
  description = "Number of rate limiting rules configured."
  value       = length(cloudflare_ruleset.rate_limiting.rules)
}
