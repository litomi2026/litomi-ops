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

  automated_user_agent_keywords = [
    "acunetix",
    "aiohttp",
    "axios/",
    "curl/",
    "dart/",
    "dirbuster",
    "ffuf",
    "go-http-client",
    "gobuster",
    "guzzlehttp",
    "headless",
    "headlesschrome",
    "httpie",
    "httpclient",
    "httpx",
    "hydra",
    "java/",
    "libcurl",
    "libwww-perl",
    "masscan",
    "mechanize",
    "nessus",
    "nikto",
    "node-fetch",
    "nuclei",
    "phantomjs",
    "playwright",
    "puppeteer",
    "python-requests",
    "python-urllib",
    "scraper",
    "scrapy",
    "selenium",
    "slimerjs",
    "sqlmap",
    "undici",
    "urllib3",
    "webdriver",
    "wget",
    "wpscan",
    "zgrab",
  ]

  unverified_bot_user_agent_keywords = [
    "bot",
    "crawl",
    "spider",
  ]

  automated_user_agent_expression = join(" ", [
    "(",
    "http.user_agent eq \"\"",
    "or",
    join(" or ", [
      for keyword in local.automated_user_agent_keywords :
      format("lower(http.user_agent) contains \"%s\"", keyword)
    ]),
    "or (",
    "not cf.client.bot",
    "and (",
    join(" or ", [
      for keyword in local.unverified_bot_user_agent_keywords :
      format("lower(http.user_agent) contains \"%s\"", keyword)
    ]),
    ")",
    ")",
    ")",
  ])

  malformed_next_action_expression = join(" ", [
    "(",
    "has_key(http.request.headers, \"next-action\")",
    "and (",
    "http.request.method ne \"POST\"",
    "or any(len(http.request.headers[\"next-action\"][*])[*] lt 32)",
    "or any(len(http.request.headers[\"next-action\"][*])[*] gt 128)",
    ")",
    ")",
  ])

  api_hosts = [
    "api.litomi.in",
    "api-stg.litomi.in",
  ]

  browser_resource_hosts = [
    "img.litomi.in",
    "img-stg.litomi.in",
    "vercel.litomi.in",
    "vercel-stg.litomi.in",
    "vercel2.litomi.in",
    "vercel2-stg.litomi.in",
  ]

  mutating_methods = [
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
  ]

  api_host_expression_set = format("{%s}", join(" ", [
    for host in local.api_hosts :
    format("\"%s\"", host)
  ]))

  browser_resource_host_expression_set = format("{%s}", join(" ", [
    for host in local.browser_resource_hosts :
    format("\"%s\"", host)
  ]))

  mutating_method_expression_set = format("{%s}", join(" ", [
    for method in local.mutating_methods :
    format("\"%s\"", method)
  ]))

  api_host_request_expression      = format("(http.host in %s)", local.api_host_expression_set)
  browser_resource_host_expression = format("(http.host in %s)", local.browser_resource_host_expression_set)

  sec_fetch_site_present_expression = "has_key(http.request.headers, \"sec-fetch-site\")"
  sec_fetch_site_values_expression  = "lower(http.request.headers[\"sec-fetch-site\"][*])[*]"

  trusted_sec_fetch_site_expression = format(
    "any(%s in {\"same-site\" \"same-origin\"})",
    local.sec_fetch_site_values_expression,
  )

  cross_site_sec_fetch_expression = format(
    "(%s and any(%s eq \"cross-site\"))",
    local.sec_fetch_site_present_expression,
    local.sec_fetch_site_values_expression,
  )

  cross_site_mutating_sec_fetch_expression = format(
    "(%s and http.request.method in %s)",
    local.cross_site_sec_fetch_expression,
    local.mutating_method_expression_set,
  )

  untrusted_sec_fetch_site_expression = format(
    "(%s and not %s)",
    local.sec_fetch_site_present_expression,
    local.trusted_sec_fetch_site_expression,
  )

  missing_or_untrusted_sec_fetch_site_expression = format(
    "(not %s or not %s)",
    local.sec_fetch_site_present_expression,
    local.trusted_sec_fetch_site_expression,
  )

  api_untrusted_sec_fetch_expression = format(
    "(%s and %s)",
    local.api_host_request_expression,
    local.untrusted_sec_fetch_site_expression,
  )

  browser_resource_untrusted_sec_fetch_expression = format(
    "(%s and %s)",
    local.browser_resource_host_expression,
    local.missing_or_untrusted_sec_fetch_site_expression,
  )

  automated_or_malformed_request_expression = join(" ", [
    local.automated_user_agent_expression,
    "or",
    local.malformed_next_action_expression,
    "or",
    local.cross_site_mutating_sec_fetch_expression,
    "or",
    local.api_untrusted_sec_fetch_expression,
    "or",
    local.browser_resource_untrusted_sec_fetch_expression,
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
      description = "Block automated, malformed, or cross-site requests"
      expression  = local.automated_or_malformed_request_expression
      action      = "block"
    }
  ]
}

output "waf_custom_rules_count" {
  description = "Number of WAF custom rules configured."
  value       = length(cloudflare_ruleset.waf_custom.rules)
}
