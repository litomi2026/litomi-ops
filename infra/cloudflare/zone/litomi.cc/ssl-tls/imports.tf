# Transient import blocks — adopt existing Cloudflare configuration into state.
# Safe to delete after the first successful HCP apply records them in state.

import {
  to = cloudflare_zone_setting.ssl
  id = "${var.zone_id}/ssl"
}
