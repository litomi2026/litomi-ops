# Transient import block — adopt the existing Always Online setting into state.
# Safe to delete after the first successful HCP apply records it in state.

import {
  to = cloudflare_zone_setting.always_online
  id = "${data.cloudflare_zone.this.zone_id}/always_online"
}
