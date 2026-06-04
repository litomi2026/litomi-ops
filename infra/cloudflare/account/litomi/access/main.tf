terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.16.0, < 6.0.0"
    }
  }
}

provider "cloudflare" {}

variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "domain" {
  description = "Primary Cloudflare zone name."
  type        = string
  default     = "litomi.in"
  nullable    = false
}

variable "access_allowed_emails" {
  description = "Exact email allowlist for Litomi internal Cloudflare Access apps."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.access_allowed_emails) > 0
    error_message = "access_allowed_emails must contain at least one email; internal apps must fail closed."
  }
}

locals {
  internal_apps_session_duration = "160h"
  internal_stg_hostname          = "stg.${var.domain}"
}

resource "cloudflare_zero_trust_access_policy" "internal_apps_allow" {
  account_id       = var.account_id
  name             = "Litomi Internal Apps Allow"
  decision         = "allow"
  session_duration = local.internal_apps_session_duration

  include = [
    for email in var.access_allowed_emails : {
      email = { email = email }
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "internal_apps" {
  account_id = var.account_id

  name = "Litomi Internal Apps"
  type = "self_hosted"

  destinations = [
    { uri = local.internal_stg_hostname },
  ]

  session_duration          = local.internal_apps_session_duration
  auto_redirect_to_identity = true
  enable_binding_cookie     = true

  policies = [
    {
      precedence = 1
      id         = cloudflare_zero_trust_access_policy.internal_apps_allow.id
    }
  ]
}
