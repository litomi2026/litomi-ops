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

variable "zone_id" {
  description = "Cloudflare zone ID for litomi.cc."
  type        = string
  nullable    = false
}

# Speed
resource "cloudflare_zone_setting" "early_hints" {
  zone_id    = var.zone_id
  setting_id = "early_hints"
  value      = "on"
}

# Scrape Shield
resource "cloudflare_zone_setting" "hotlink_protection" {
  zone_id    = var.zone_id
  setting_id = "hotlink_protection"
  value      = "on"
}

# Security
resource "cloudflare_zone_setting" "challenge_ttl" {
  zone_id    = var.zone_id
  setting_id = "challenge_ttl"
  value      = 57600
}
