data "cloudflare_rulesets" "zone" {
  zone_id = var.zone_id
}

locals {
  rate_limiting_ruleset_id = one([
    for ruleset in data.cloudflare_rulesets.zone.rulesets :
    ruleset.id
    if ruleset.kind == "zone" && ruleset.phase == "http_ratelimit" && ruleset.name == "default"
  ])
}

import {
  to = cloudflare_ruleset.rate_limiting
  id = "zones/${var.zone_id}/${local.rate_limiting_ruleset_id}"
}
