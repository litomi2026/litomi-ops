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

locals {
  root_web_cache_hostname = var.domain

  public_locales = [
    "en",
    "ja",
    "zh-CN",
  ]

  ttl_day_path_prefixes = [
    "____",
  ]

  ttl_6h_locale_variant_path_prefixes = [
    // 인기 페이지 순위 revalidate
    "/ranking/",

    // right-aside 일간 조회수 순위 revalidate
    "/@",
    "/censor",
    "/donation",
    "/notification",
    "/post",
  ]

  ttl_10s_path_equals = [
    "____",
  ]

  respect_origin_path_prefixes = [
    "/api/",
    "/oauth/",
    "/.well-known/",
  ]

  respect_origin_path_equals = [
    "/api",
  ]

  respect_origin_locale_variant_path_prefixes = [
    "/settings",
  ]

  respect_origin_hostnames = [
    "argocd.${var.domain}",
    "proxy.${var.domain}",
    "proxy2.${var.domain}",
    "vercel.${var.domain}",
  ]

  bypass_cache_path_prefixes = [
    "/cdn-cgi/",
  ]

  bypass_cache_path_equals = [
    "/health",
    "/api/health",
  ]

  bypass_cache_locale_variant_path_prefixes = [
    "____",
  ]

  bypass_cache_hostnames = [
    "____",
  ]

  r2_cache_hostname = "r2.${var.domain}"

  img_cache_hostnames = [
    "img.${var.domain}",
    "img-stg.${var.domain}",
  ]
}

locals {
  expanded_ttl_6h_path_prefixes = flatten([
    for prefix in local.ttl_6h_locale_variant_path_prefixes :
    concat([prefix], [
      for locale in local.public_locales :
      "/${locale}${prefix}"
    ])
  ])

  expanded_bypass_cache_path_prefixes = flatten([
    for prefix in local.bypass_cache_locale_variant_path_prefixes :
    concat([prefix], [
      for locale in local.public_locales :
      "/${locale}${prefix}"
    ])
  ])

  expanded_respect_origin_path_prefixes = flatten([
    for prefix in local.respect_origin_locale_variant_path_prefixes :
    concat([prefix], [
      for locale in local.public_locales :
      "/${locale}${prefix}"
    ])
  ])

  all_respect_origin_path_prefixes = concat(
    local.respect_origin_path_prefixes,
    local.expanded_respect_origin_path_prefixes,
  )

  all_bypass_cache_path_prefixes = concat(
    local.bypass_cache_path_prefixes,
    local.expanded_bypass_cache_path_prefixes,
  )

  respect_origin_path_conditions = join(" or ", concat(
    [
      for path in local.respect_origin_path_equals :
      "(http.request.uri.path eq \"${path}\")"
    ],
    [
      for prefix in local.all_respect_origin_path_prefixes :
      "(starts_with(http.request.uri.path, \"${prefix}\"))"
    ],
  ))

  respect_origin_host_conditions = join(" or ", [
    for hostname in local.respect_origin_hostnames :
    "(http.host eq \"${hostname}\")"
  ])

  respect_origin_conditions = "${local.respect_origin_path_conditions} or ${local.respect_origin_host_conditions}"

  ttl_day_conditions = join(" or ", [
    for prefix in local.ttl_day_path_prefixes :
    "(starts_with(http.request.uri.path, \"${prefix}\"))"
  ])

  ttl_6h_conditions = join(" or ", [
    for prefix in local.expanded_ttl_6h_path_prefixes :
    "(starts_with(http.request.uri.path, \"${prefix}\"))"
  ])

  ttl_10s_conditions = join(" or ", [
    for path in local.ttl_10s_path_equals :
    "(http.request.uri.path eq \"${path}\")"
  ])

  bypass_cache_conditions = join(" or ", concat(
    [
      for path in local.bypass_cache_path_equals :
      "(http.request.uri.path eq \"${path}\")"
    ],
    [
      for prefix in local.all_bypass_cache_path_prefixes :
      "(starts_with(http.request.uri.path, \"${prefix}\"))"
    ],
  ))

  bypass_cache_host_conditions = join(" or ", [
    for hostname in local.bypass_cache_hostnames :
    "(http.host eq \"${hostname}\")"
  ])

  img_cache_conditions = join(" or ", [
    for hostname in local.img_cache_hostnames :
    "((http.host eq \"${hostname}\") and starts_with(http.request.uri.path, \"/i/\"))"
  ])

  r2_cache_conditions = "(http.host eq \"${local.r2_cache_hostname}\")"
  ttl_30d_expression  = "(http.host eq \"${local.root_web_cache_hostname}\")"
}

resource "cloudflare_ruleset" "cache_rules" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "Cache Rules"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules = [
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
      ref         = "root_web_30d"
      enabled     = true
      description = "Cache root web host with 30 days TTL"
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
      expression  = local.r2_cache_conditions
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
