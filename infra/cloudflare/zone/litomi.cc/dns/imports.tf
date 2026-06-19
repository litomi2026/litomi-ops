# Transient import blocks — adopt existing Cloudflare configuration into state.
# Safe to delete after the first successful HCP apply records them in state.

import {
  to = cloudflare_dns_record.google_verification2_txt
  id = "${data.cloudflare_zone.this.zone_id}/0f319ff7196207e03d82b5e7fae87ea2"
}

import {
  to = cloudflare_zone_dnssec.litomi_cc
  id = data.cloudflare_zone.this.zone_id
}
