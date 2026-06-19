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

resource "cloudflare_bot_management" "default" {
  zone_id = data.cloudflare_zone.this.zone_id

  ai_bots_protection      = "block"
  content_bots_protection = "disabled"
  crawler_protection      = "enabled"
  enable_js               = true
  fight_mode              = true
  is_robots_txt_managed   = true
}

output "bot_management_ai_bots_protection" {
  description = "Configured AI bots protection mode."
  value       = cloudflare_bot_management.default.ai_bots_protection
}

output "bot_management_fight_mode_enabled" {
  description = "Whether Bot Fight Mode is enabled."
  value       = cloudflare_bot_management.default.fight_mode
}
