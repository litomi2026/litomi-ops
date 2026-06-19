# Transient import block — adopt the existing leaked credential check state.
# Safe to delete after the first successful HCP apply records it in state.

import {
  to = cloudflare_leaked_credential_check.this
  id = data.cloudflare_zone.this.zone_id
}
