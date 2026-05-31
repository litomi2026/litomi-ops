terraform {
  cloud {
    organization = "litomi"

    workspaces {
      project = "cloudflare"
      name    = "zone-litomi-in-cache"
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

locals {
  img_cache_hostnames = [
    "img.${var.domain}",
    "img-stg.${var.domain}",
  ]

  respect_origin_prefixes = [
    "/api/",
  ]

  ttl_30d_path_equals = [
    "/",
    "/app",
    "/chat",
  ]

  ttl_30d_extension_equals = [
    "webmanifest",
  ]

  ttl_30d_path_prefixes = [
    "/_next/image",
    "/_not-found",
    "/app.",
    "/apple-",
    "/auth/login",
    "/auth/signup",
    "/deterrence",
    "/doc/",
    "/en/",
    "/favicon.",
    "/icon.",
    "/image/",
    "/ja/",
    "/libo",
    "/library",
    "/manga",
    "/new/",
    "/nye",
    "/notification",
    "/offline.html",
    "/og-image.",
    "/posts/",
    "/random",
    "/realtime",
    "/recommend/manga",
    "/robots.txt",
    "/search",
    "/sitemap.xml",
    "/tag",
    "/webtoon",
    "/web-app-manifest",
    "/zh-CN/",
    "/404",
    "/@",
  ]

  ttl_day_path_prefixes = [
    "___",
  ]

  ttl_6h_path_prefixes = [
    "/ranking/",
  ]

  ttl_10s_path_equals = [
    "___",
  ]

  bypass_cache_path_prefixes = [
    "/.well-known/",
    "/cdn-cgi/challenge-platform/",
    "/en/settings",
    "/ja/settings",
    "/settings",
    "/zh-CN/settings",
  ]

  bypass_cache_hostnames = [
    "grafana.${var.domain}",
    "argocd.${var.domain}",
    "stg.${var.domain}",
  ]

  respect_origin_conditions = join(" or ", [
    for prefix in local.respect_origin_prefixes :
    "(starts_with(http.request.uri.path, \"${prefix}\"))"
  ])

  exact_path_conditions = join(" or ", [
    for path in local.ttl_30d_path_equals :
    "(http.request.uri.path eq \"${path}\")"
  ])

  exact_extension_conditions = join(" ", [
    for extension in local.ttl_30d_extension_equals :
    "\"${extension}\""
  ])

  prefix_path_conditions = join(" or ", [
    for prefix in local.ttl_30d_path_prefixes :
    "(starts_with(http.request.uri.path, \"${prefix}\"))"
  ])

  ttl_day_conditions = join(" or ", [
    for prefix in local.ttl_day_path_prefixes :
    "(starts_with(http.request.uri.path, \"${prefix}\"))"
  ])

  ttl_6h_conditions = join(" or ", [
    for prefix in local.ttl_6h_path_prefixes :
    "(starts_with(http.request.uri.path, \"${prefix}\"))"
  ])

  ttl_10s_conditions = join(" or ", [
    for path in local.ttl_10s_path_equals :
    "(http.request.uri.path eq \"${path}\")"
  ])

  bypass_cache_conditions = join(" or ", [
    for prefix in local.bypass_cache_path_prefixes :
    "(starts_with(http.request.uri.path, \"${prefix}\"))"
  ])

  bypass_cache_host_conditions = join(" or ", [
    for hostname in local.bypass_cache_hostnames :
    "(http.host eq \"${hostname}\")"
  ])

  img_cache_conditions = join(" or ", [
    for hostname in local.img_cache_hostnames :
    "((http.host eq \"${hostname}\") and starts_with(http.request.uri.path, \"/i/\"))"
  ])

  ttl_30d_expression = "${local.exact_path_conditions} or ${local.prefix_path_conditions} or (http.request.uri.path.extension in {${local.exact_extension_conditions}})"
}

resource "cloudflare_ruleset" "cache_rules" {
  zone_id = var.zone_id
  name    = "Cache Rules"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules = [
    {
      ref         = "respect_origin_cache_control"
      enabled     = true
      description = "Respect origin cache-control"
      expression  = local.respect_origin_conditions
      action      = "set_cache_settings"

      action_parameters = {
        cache = true
        edge_ttl = {
          mode = "respect_origin"
        }
        browser_ttl = {
          mode = "respect_origin"
        }
        cache_key = {
          cache_deception_armor      = true
          ignore_query_strings_order = true
        }
      }
    },
    {
      ref         = "img_proxy_30d"
      enabled     = true
      description = "Respect origin cache-control while ignoring query strings"
      expression  = local.img_cache_conditions
      action      = "set_cache_settings"

      action_parameters = {
        cache = true
        edge_ttl = {
          mode = "respect_origin"
        }
        browser_ttl = {
          mode = "respect_origin"
        }
        cache_key = {
          cache_deception_armor = true
          custom_key = {
            query_string = {
              exclude = {
                all = true
              }
            }
          }
        }
      }
    },
    {
      ref         = "manga_pages_html"
      enabled     = true
      description = "Cache with 30 days TTL"
      expression  = local.ttl_30d_expression
      action      = "set_cache_settings"

      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = "override_origin"
          default = 2592000
        }
        browser_ttl = {
          mode = "respect_origin"
        }
        cache_key = {
          cache_deception_armor      = true
          ignore_query_strings_order = true
        }
      }
    },
    {
      ref         = "isr_day"
      enabled     = true
      description = "Cache with 1 day TTL"
      expression  = local.ttl_day_conditions
      action      = "set_cache_settings"

      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = "override_origin"
          default = 86400
        }
        browser_ttl = {
          mode = "respect_origin"
        }
        cache_key = {
          cache_deception_armor      = true
          ignore_query_strings_order = true
        }
      }
    },
    {
      ref         = "isr_hour"
      enabled     = true
      description = "Cache with 6 hours TTL"
      expression  = local.ttl_6h_conditions
      action      = "set_cache_settings"

      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = "override_origin"
          default = 21600
        }
        browser_ttl = {
          mode = "respect_origin"
        }
        cache_key = {
          cache_deception_armor      = true
          ignore_query_strings_order = true
        }
      }
    },
    {
      ref         = "ttl_10s"
      enabled     = true
      description = "Cache with 10 seconds TTL"
      expression  = local.ttl_10s_conditions
      action      = "set_cache_settings"

      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = "override_origin"
          default = 10
        }
        browser_ttl = {
          mode = "respect_origin"
        }
        cache_key = {
          cache_deception_armor      = true
          ignore_query_strings_order = true
        }
      }
    },
    {
      ref         = "r2_storage"
      enabled     = true
      description = "Override cache for R2 storage"
      expression  = "(http.host eq \"r2.${var.domain}\")"
      action      = "set_cache_settings"

      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = "override_origin"
          default = 31536000
        }
        browser_ttl = {
          mode    = "override_origin"
          default = 86400
        }
        cache_key = {
          cache_deception_armor      = true
          ignore_query_strings_order = true
        }
      }
    },
    {
      ref         = "bypass_cache"
      enabled     = true
      description = "Bypass cache for paths or hostnames"
      expression  = "(${local.bypass_cache_conditions}) or (${local.bypass_cache_host_conditions})"
      action      = "set_cache_settings"

      action_parameters = {
        cache = false
      }
    },
  ]
}

output "cache_rules_count" {
  description = "Number of cache rules configured."
  value       = length(cloudflare_ruleset.cache_rules.rules)
}
