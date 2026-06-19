# Transient import blocks — adopt existing Cloudflare configuration into state.
# Safe to delete after the first successful HCP apply records them in state.

import {
  to = cloudflare_zone_setting.ssl
  id = "${var.zone_id}/ssl"
}

import {
  to = cloudflare_zone_setting.zero_rtt
  id = "${var.zone_id}/0rtt"
}

import {
  to = cloudflare_zone_setting.ech
  id = "${var.zone_id}/ech"
}

import {
  to = cloudflare_zone_setting.pq_keyex
  id = "${var.zone_id}/pq_keyex"
}
