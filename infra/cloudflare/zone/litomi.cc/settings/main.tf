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
