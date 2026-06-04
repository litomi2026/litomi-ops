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

variable "blocked_source_ips" {
  description = "Source IPs blocked from sending non-read requests to the production API."
  type        = list(string)
  default     = []
  nullable    = false
  sensitive   = true
}

locals {
  # Leaked credential check
  leaked_credential_check_expression = "(cf.waf.credential_check.password_leaked)"

  # AI Crawl Control
  ai_crawl_control_user_agents = [
    "Applebot",
    "archive.org_bot",
    "Arquivo-web-crawler",
    "ChatGPT-User",
    "DuckAssistBot",
    "Manus-User",
    "meta-externalfetcher",
    "MistralAI-User",
    "OAI-SearchBot",
    "Perplexity-User",
    "PerplexityBot",
    "ProRataInc",
    "Terracotta",
  ]

  ai_crawl_control_expression = format(
    "(http.request.uri.path ne \"/robots.txt\") and (%s)",
    join(" or ", [
      for user_agent in local.ai_crawl_control_user_agents :
      format("(http.user_agent contains \"%s\")", user_agent)
    ]),
  )

  # Block abusive requests from configured source IPs
  blocked_source_ip_set = format(
    "{%s}",
    join(" ", var.blocked_source_ips),
  )

  api_read_methods = [
    "GET",
    "HEAD",
  ]

  api_read_method_expression_set = format("{%s}", join(" ", [
    for method in local.api_read_methods :
    format("\"%s\"", method)
  ]))

  abusive_request_expression = length(var.blocked_source_ips) == 0 ? "(http.request.uri.path eq \"/__disabled_abusive_requests__\")" : join(" ", [
    "(",
    format("ip.src in %s", local.blocked_source_ip_set),
    "and http.host eq \"api.litomi.in\"",
    format("and not (http.request.method in %s)", local.api_read_method_expression_set),
    ")",
  ])

  # Allow /.well_known/* request
  public_well_known_methods = [
    "GET",
    "HEAD",
  ]

  public_well_known_method_expression_set = format("{%s}", join(" ", [
    for method in local.public_well_known_methods :
    format("\"%s\"", method)
  ]))

  public_well_known_request_expression = join(" ", [
    "(",
    "starts_with(http.request.uri.path, \"/.well-known/\")",
    format("and http.request.method in %s", local.public_well_known_method_expression_set),
    ")",
  ])

  # Unexpected Next.js Server Action header
  malformed_next_action_expression = "(has_key(http.request.headers, \"next-action\"))"

  # Cross-site mutating request
  sec_fetch_site_present_expression = "has_key(http.request.headers, \"sec-fetch-site\")"
  sec_fetch_site_values_expression  = "lower(http.request.headers[\"sec-fetch-site\"][*])[*]"

  cross_site_sec_fetch_expression = format(
    "(%s and any(%s eq \"cross-site\"))",
    local.sec_fetch_site_present_expression,
    local.sec_fetch_site_values_expression,
  )

  mutating_methods = [
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
  ]

  mutating_method_expression_set = format("{%s}", join(" ", [
    for method in local.mutating_methods :
    format("\"%s\"", method)
  ]))

  cross_site_mutating_sec_fetch_expression = format(
    "(%s and http.request.method in %s)",
    local.cross_site_sec_fetch_expression,
    local.mutating_method_expression_set,
  )

  # Corrupted request
  corrupted_request_expression = format(
    "(not %s and (%s))",
    local.public_well_known_request_expression,
    join(" or ", [
      local.automated_user_agent_expression,
      local.malformed_next_action_expression,
      local.cross_site_mutating_sec_fetch_expression,
      local.untrusted_initiator_protected_request_expression,
      ]
    ),
  )
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
      ref         = "block_abusive_requests"
      enabled     = length(var.blocked_source_ips) > 0
      description = "Block abusive requests from configured source IPs"
      expression  = local.abusive_request_expression
      action      = "block"
    },
    {
      ref         = "block_automated_or_malformed_requests"
      enabled     = true
      description = "Block corrupted requests"
      expression  = local.corrupted_request_expression
      action      = "block"
    }
  ]
}

output "waf_custom_rules_count" {
  description = "Number of WAF custom rules configured."
  value       = length(cloudflare_ruleset.waf_custom.rules)
}
