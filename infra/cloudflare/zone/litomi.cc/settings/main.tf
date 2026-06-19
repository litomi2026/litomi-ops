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

# Speed
resource "cloudflare_zone_setting" "early_hints" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "early_hints"
  value      = "on"
}

# Scrape Shield
resource "cloudflare_zone_setting" "hotlink_protection" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "hotlink_protection"
  value      = "on"
}

# Security
resource "cloudflare_zone_setting" "challenge_ttl" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "challenge_ttl"
  value      = 57600
}

# Always Online
resource "cloudflare_zone_setting" "always_online" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "always_online"
  value      = "on"
}

# Browser Integrity Check
resource "cloudflare_zone_setting" "browser_check" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "browser_check"
  value      = "on"
}

# Email Address Obfuscation
resource "cloudflare_zone_setting" "email_obfuscation" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "email_obfuscation"
  value      = "on"
}

# Replace insecure JavaScript libraries
resource "cloudflare_zone_setting" "replace_insecure_js" {
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "replace_insecure_js"
  value      = "on"
}
