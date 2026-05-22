data "cloudflare_zero_trust_access_applications" "internal_apps" {
  account_id = var.account_id
  name       = "Litomi Internal Apps"
  exact      = true
}

data "cloudflare_zero_trust_access_policies" "account" {
  account_id = var.account_id
}

locals {
  internal_apps_access_policy_id = one([
    for policy in data.cloudflare_zero_trust_access_policies.account.result :
    policy.id
    if policy.name == "Litomi Internal Apps Allow"
  ])
}

import {
  to = cloudflare_zero_trust_access_policy.internal_apps_allow
  id = "${var.account_id}/${local.internal_apps_access_policy_id}"
}

import {
  to = cloudflare_zero_trust_access_application.internal_apps
  id = "accounts/${var.account_id}/${one(data.cloudflare_zero_trust_access_applications.internal_apps.result).id}"
}
