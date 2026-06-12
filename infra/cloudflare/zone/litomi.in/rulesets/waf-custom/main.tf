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

  api_request_expression = join(" ", [
    "(",
    "http.host eq \"litomi.in\"",
    "and starts_with(http.request.uri.path, \"/api/\")",
    ")",
  ])

  abusive_request_expression = join(" ", [
    "(",
    format("ip.src in %s", local.blocked_source_ip_set),
    "and ${local.api_request_expression}",
    format("and not (http.request.method in %s)", local.api_read_method_expression_set),
    ")",
  ])

  # Allow public read-only utility endpoints
  public_methods = [
    "GET",
    "HEAD",
  ]

  public_paths = [
    "/health",
    "/api/health",
  ]

  public_prefixes = [
    "/.well-known/",
  ]

  public_method_expression_set = format("{%s}", join(" ", [
    for method in local.public_methods :
    format("\"%s\"", method)
  ]))

  public_path_expression_set = format("{%s}", join(" ", [
    for path in local.public_paths :
    format("\"%s\"", path)
  ]))

  public_path_expression = join(" or ", concat(
    [
      format("http.request.uri.path in %s", local.public_path_expression_set),
    ],
    [
      for prefix in local.public_prefixes :
      format("starts_with(http.request.uri.path, \"%s\")", prefix)
    ],
  ))

  public_request_expression = join(" ", [
    "(",
    "(${local.public_path_expression})",
    format("and http.request.method in %s", local.public_method_expression_set),
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
  corrupted_request_conditions = concat(
    [
      local.automated_user_agent_expression,
      local.malformed_next_action_expression,
      local.cross_site_mutating_sec_fetch_expression,
      local.untrusted_initiator_protected_request_expression,
    ],
    length(var.blocked_source_ips) > 0 ? [local.abusive_request_expression] : [],
  )

  corrupted_request_expression = format(
    "(not %s and (%s))",
    local.public_request_expression,
    join(" or ", local.corrupted_request_conditions),
  )

  # Adult gate
  adult_access_cookie = "__Secure-adult-pass=1"

  adult_gate_protected_path_prefixes = [
    "/api/proxy/",
    "/api/v1/library/",
    "/api/v1/post",
    "/i/",
  ]

  adult_gate_protected_content_condition = join(" or ", [
    for prefix in local.adult_gate_protected_path_prefixes :
    format("(starts_with(http.request.uri.path, \"%s\"))", prefix)
  ])

  adult_gate_kr_deterrence_condition = join(" and ", [
    local.adult_gate_protected_content_condition,
    "(ip.src.country eq \"KR\")",
    "(not http.cookie contains \"${local.adult_access_cookie}\")",
  ])

  # Turnstile pre-clearance gate
  edge_proxy_host_expression_set = "{\"vercel.litomi.in\" \"vercel-stg.litomi.in\" \"vercel2.litomi.in\" \"vercel2-stg.litomi.in\"}"

  edge_proxy_turnstile_expression = join(" ", [
    "(",
    format("http.host in %s", local.edge_proxy_host_expression_set),
    "and starts_with(http.request.uri.path, \"/api/proxy/\")",
    "and http.request.method ne \"OPTIONS\"",
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
      ref         = "block_automated_or_malformed_requests"
      enabled     = true
      description = "Block automated, malformed, or abusive requests"
      expression  = local.corrupted_request_expression
      action      = "block"
    },
    {
      ref         = "adult_gate_kr_deterrence"
      enabled     = true
      description = "Block Korean adult-gated API/image traffic"
      expression  = local.adult_gate_kr_deterrence_condition
      action      = "block"
    },
    {
      ref         = "managed_challenge_edge_proxy_api"
      enabled     = true
      description = "Require Turnstile clearance"
      expression  = local.edge_proxy_turnstile_expression
      action      = "managed_challenge"
    }
  ]
}

output "waf_custom_rules_count" {
  description = "Number of WAF custom rules configured."
  value       = length(cloudflare_ruleset.waf_custom.rules)
}
