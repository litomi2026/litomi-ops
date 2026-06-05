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

variable "cloudflare_access_team_name" {
  description = "Cloudflare Access team name used in the account's cloudflareaccess.com OIDC issuer URL."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.cloudflare_access_team_name)) > 0
    error_message = "cloudflare_access_team_name must not be empty."
  }
}

variable "argocd_admin_emails" {
  description = "Exact email allowlist for Argo CD users."
  type        = set(string)
  nullable    = false

  validation {
    condition     = length(var.argocd_admin_emails) > 0
    error_message = "argocd_admin_emails must contain at least one email; Argo CD must have a break-glass administrator."
  }
}

variable "argocd_readonly_emails" {
  description = "[Deprecated] Exact email allowlist for Argo CD read-only users."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "stg_allowed_emails" {
  description = "Exact email allowlist for the staging application."
  type        = set(string)
  nullable    = false

  validation {
    condition     = length(var.stg_allowed_emails) > 0
    error_message = "stg_allowed_emails must contain at least one email; staging access must fail closed."
  }
}

locals {
  argocd_group_name = "litomi-argocd-users"
  stg_group_name    = "litomi-stg-users"

  argocd_session_duration = "12h"
  stg_session_duration    = "160h"

  argocd_hostname = "argocd.${var.domain}"
  stg_hostname    = "stg.${var.domain}"

  argocd_allowed_emails = setunion(
    var.argocd_admin_emails,
    var.argocd_readonly_emails,
  )
}

resource "cloudflare_zero_trust_access_group" "argocd_admins" {
  account_id = var.account_id
  name       = local.argocd_group_name

  include = [
    for email in sort(tolist(local.argocd_allowed_emails)) : {
      email = { email = email }
    }
  ]
}

resource "cloudflare_zero_trust_access_group" "stg_users" {
  account_id = var.account_id
  name       = local.stg_group_name

  include = [
    for email in sort(tolist(var.stg_allowed_emails)) : {
      email = { email = email }
    }
  ]
}

resource "cloudflare_zero_trust_access_policy" "argocd_admins_allow" {
  account_id       = var.account_id
  name             = "Argo CD Users Allow"
  decision         = "allow"
  session_duration = local.argocd_session_duration

  include = [
    {
      group = { id = cloudflare_zero_trust_access_group.argocd_admins.id }
    }
  ]
}

resource "cloudflare_zero_trust_access_policy" "argocd_webhook_bypass" {
  account_id = var.account_id
  name       = "Argo CD Webhook Bypass"
  decision   = "bypass"

  include = [
    {
      everyone = {}
    }
  ]
}

resource "cloudflare_zero_trust_access_policy" "stg_users_allow" {
  account_id       = var.account_id
  name             = "Staging Users Allow"
  decision         = "allow"
  session_duration = local.stg_session_duration

  include = [
    {
      group = { id = cloudflare_zero_trust_access_group.stg_users.id }
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "argocd" {
  account_id = var.account_id

  name = "Argo CD"
  type = "self_hosted"

  destinations = [
    {
      uri = local.argocd_hostname
    }
  ]

  session_duration          = local.argocd_session_duration
  auto_redirect_to_identity = true
  enable_binding_cookie     = false

  policies = [
    {
      precedence = 1
      id         = cloudflare_zero_trust_access_policy.argocd_admins_allow.id
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "argocd_webhook" {
  account_id = var.account_id

  name = "Argo CD Webhook"
  type = "self_hosted"

  destinations = [
    {
      uri = "${local.argocd_hostname}/api/webhook"
    }
  ]

  app_launcher_visible = false

  policies = [
    {
      precedence = 1
      id         = cloudflare_zero_trust_access_policy.argocd_webhook_bypass.id
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "argocd_oidc" {
  account_id = var.account_id

  name = "Argo CD OIDC"
  type = "saas"

  saas_app = {
    auth_type             = "oidc"
    access_token_lifetime = "1h"
    grant_types           = ["authorization_code"]
    redirect_uris         = ["https://${local.argocd_hostname}/auth/callback"]
    scopes                = ["openid", "email", "profile"]
  }

  policies = [
    {
      precedence = 1
      id         = cloudflare_zero_trust_access_policy.argocd_admins_allow.id
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "stg" {
  account_id = var.account_id

  name = "Staging"
  type = "self_hosted"

  destinations = [
    {
      uri = local.stg_hostname
    }
  ]

  session_duration          = local.stg_session_duration
  auto_redirect_to_identity = true
  enable_binding_cookie     = true

  policies = [
    {
      precedence = 1
      id         = cloudflare_zero_trust_access_policy.stg_users_allow.id
    }
  ]
}

output "argocd_oidc_client_id" {
  description = "Cloudflare Access OIDC client ID for Argo CD. Copy this to the Argo CD OCI Vault secret property CLOUDFLARE_ACCESS_ARGOCD_CLIENT_ID."
  value       = cloudflare_zero_trust_access_application.argocd_oidc.saas_app.client_id
}

output "argocd_oidc_client_secret" {
  description = "Cloudflare Access OIDC client secret for Argo CD. Copy this to the Argo CD OCI Vault secret property CLOUDFLARE_ACCESS_ARGOCD_CLIENT_SECRET."
  value       = cloudflare_zero_trust_access_application.argocd_oidc.saas_app.client_secret
  sensitive   = true
}

output "argocd_oidc_issuer" {
  description = "Cloudflare Access OIDC issuer for Argo CD. Copy this to the Argo CD OCI Vault secret property CLOUDFLARE_ACCESS_ARGOCD_ISSUER."
  value       = "https://${var.cloudflare_access_team_name}.cloudflareaccess.com/cdn-cgi/access/sso/oidc/${cloudflare_zero_trust_access_application.argocd_oidc.saas_app.client_id}"
}
