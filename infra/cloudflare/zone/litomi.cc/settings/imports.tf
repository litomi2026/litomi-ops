# Transient import block — adopt the existing Always Online setting into state.
# Safe to delete after the first successful HCP apply records it in state.

import {
  to = cloudflare_zone_setting.always_online
  id = "${data.cloudflare_zone.this.zone_id}/always_online"
}

import {
  to = cloudflare_zone_setting.browser_check
  id = "${data.cloudflare_zone.this.zone_id}/browser_check"
}

import {
  to = cloudflare_zone_setting.email_obfuscation
  id = "${data.cloudflare_zone.this.zone_id}/email_obfuscation"
}

import {
  to = cloudflare_zone_setting.replace_insecure_js
  id = "${data.cloudflare_zone.this.zone_id}/replace_insecure_js"
}
