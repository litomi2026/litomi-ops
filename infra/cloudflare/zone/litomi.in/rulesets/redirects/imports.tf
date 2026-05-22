data "cloudflare_rulesets" "zone" {
  zone_id = var.zone_id
}

locals {
  www_redirect_ruleset_id = one([
    for ruleset in data.cloudflare_rulesets.zone.rulesets :
    ruleset.id
    if ruleset.kind == "zone" && ruleset.phase == "http_request_dynamic_redirect" && ruleset.name == "WWW Redirect"
  ])
}

import {
  to = cloudflare_ruleset.www_redirect
  id = "zones/${var.zone_id}/${local.www_redirect_ruleset_id}"
}
