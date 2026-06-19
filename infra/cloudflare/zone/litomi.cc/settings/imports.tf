# Transient import blocks — adopt existing Cloudflare configuration into state.
# Safe to delete after the first successful HCP apply records them in state.

import {
  to = cloudflare_zone_setting.early_hints
  id = "${var.zone_id}/early_hints"
}

import {
  to = cloudflare_zone_setting.hotlink_protection
  id = "${var.zone_id}/hotlink_protection"
}

import {
  to = cloudflare_zone_setting.challenge_ttl
  id = "${var.zone_id}/challenge_ttl"
}
