terraform {
  cloud {
    organization = "litomi"

    workspaces {
      project = "cloudflare"
      name    = "zone-litomi-in-waf-custom"
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
  leaked_credential_check_expression = "(cf.waf.credential_check.password_leaked)"

  ai_crawl_control_expression = "(http.request.uri.path ne \"/robots.txt\") and ((http.user_agent contains \"bingbot\"))"

  malformed_next_action_expression = join(" ", [
    "(",
    "len(http.request.headers[\"next-action\"]) >= 0",
    "and (",
    "http.request.method ne \"POST\"",
    "or any(len(http.request.headers[\"next-action\"][*])[*] lt 32)",
    "or any(len(http.request.headers[\"next-action\"][*])[*] gt 128)",
    ")",
    ")",
  ])
}

resource "cloudflare_ruleset" "waf_custom" {
  zone_id     = var.zone_id
  name        = "default"
  description = ""
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    {
      ref         = "a3ca108d1687433ebce38790e303e6cd"
      enabled     = true
      description = "Leaked credential check"
      expression  = local.leaked_credential_check_expression
      action      = "managed_challenge"
    },
    {
      ref         = "[CF AI Audit]"
      enabled     = true
      description = "AI Crawl Control - Block AI bots by User Agent"
      expression  = local.ai_crawl_control_expression
      action      = "block"
    },
    {
      ref         = "block_malformed_next_action"
      enabled     = true
      description = "Block malformed Next.js Server Action requests"
      expression  = local.malformed_next_action_expression
      action      = "block"
    }
  ]
}

output "waf_custom_rules_count" {
  description = "Number of WAF custom rules configured."
  value       = length(cloudflare_ruleset.waf_custom.rules)
}
