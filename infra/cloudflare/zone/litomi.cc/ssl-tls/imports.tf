# Transient import blocks — adopt existing Cloudflare configuration into state.
# Safe to delete after the first successful HCP apply records them in state.

import {
  to = cloudflare_zone_setting.ssl
  id = "${data.cloudflare_zone.this.zone_id}/ssl"
}

import {
  to = cloudflare_zone_setting.zero_rtt
  id = "${data.cloudflare_zone.this.zone_id}/0rtt"
}

import {
  to = cloudflare_zone_setting.ech
  id = "${data.cloudflare_zone.this.zone_id}/ech"
}

import {
  to = cloudflare_zone_setting.pq_keyex
  id = "${data.cloudflare_zone.this.zone_id}/pq_keyex"
}

import {
  to = cloudflare_universal_ssl_setting.default
  id = data.cloudflare_zone.this.zone_id
}

import {
  to = cloudflare_zone_setting.always_use_https
  id = "${data.cloudflare_zone.this.zone_id}/always_use_https"
}

import {
  to = cloudflare_zone_setting.automatic_https_rewrites
  id = "${data.cloudflare_zone.this.zone_id}/automatic_https_rewrites"
}

import {
  to = cloudflare_zone_setting.hsts
  id = "${data.cloudflare_zone.this.zone_id}/security_header"
}

import {
  to = cloudflare_zone_setting.min_tls_version
  id = "${data.cloudflare_zone.this.zone_id}/min_tls_version"
}

import {
  to = cloudflare_zone_setting.opportunistic_encryption
  id = "${data.cloudflare_zone.this.zone_id}/opportunistic_encryption"
}

import {
  to = cloudflare_zone_setting.tls_1_3
  id = "${data.cloudflare_zone.this.zone_id}/tls_1_3"
}
