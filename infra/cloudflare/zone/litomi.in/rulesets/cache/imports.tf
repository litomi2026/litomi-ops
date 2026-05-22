data "cloudflare_rulesets" "zone" {
  zone_id = var.zone_id
}

locals {
  cache_ruleset_id = one([
    for ruleset in data.cloudflare_rulesets.zone.rulesets :
    ruleset.id
    if ruleset.kind == "zone" && ruleset.phase == "http_request_cache_settings" && ruleset.name == "Cache Rules"
  ])
}

import {
  to = cloudflare_ruleset.cache_rules
  id = "zones/${var.zone_id}/${local.cache_ruleset_id}"
}
