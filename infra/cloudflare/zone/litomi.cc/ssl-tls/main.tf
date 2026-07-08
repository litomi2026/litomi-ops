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

variable "domain" {
  description = "Primary Cloudflare zone name."
  type        = string
  default     = "litomi.cc"
  nullable    = false
}

data "cloudflare_zone" "this" {
  filter = {
    name = var.domain
  }
}

resource "cloudflare_universal_ssl_setting" "default" {
  zone_id = data.cloudflare_zone.this.zone_id
  enabled = true
}

# Full (Strict): Cloudflare validates the origin certificate (not just encrypts).
# ⚠️ Before applying, confirm EVERY proxied origin serves a valid, non-expired,
# hostname-matching cert (OKE edge via cert-manager, Vercel, R2, and the Cloud Run
# proxy's Google-managed domain-mapping cert) — any origin with an invalid cert
# returns 526 under strict.
resource "cloudflare_zone_setting" "ssl" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "ssl"
  value      = "strict"
}

# Replaced by the "Force HTTPS except ACME" dynamic redirect rule so that the
# Cloud Run domain-mapping cert can renew over HTTP-01 through the proxy. Keeping
# this "on" would 301 the ACME challenge to HTTPS and break renewal under Strict.
resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "always_use_https"
  value      = "off"
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "hsts" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "security_header"

  value = {
    strict_transport_security = {
      enabled            = true
      include_subdomains = true
      max_age            = 31536000
      nosniff            = true
      preload            = true
    }
  }
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "opportunistic_encryption" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "opportunistic_encryption"
  value      = "on"
}

resource "cloudflare_zone_setting" "tls_1_3" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "tls_1_3"
  value      = "zrt"
}

resource "cloudflare_zone_setting" "zero_rtt" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "0rtt"
  value      = "on"
}

resource "cloudflare_zone_setting" "ech" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "ech"
  value      = "on"
}

resource "cloudflare_zone_setting" "pq_keyex" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "pq_keyex"
  value      = "on"
}
