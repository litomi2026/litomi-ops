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

# PortOne V2 webhook egress IP(s). Allow-listed so Bot Fight Mode does not issue a
# managed challenge to server-to-server webhook delivery: PortOne sends from AWS
# (ASN 16509, UA "AHC/*"), which fight_mode challenges, and the client cannot solve
# it — so the callback is dropped at the edge before reaching the API. A "whitelist"
# IP Access Rule bypasses Bot Fight Mode for these sources. PortOne notifies before
# changing the IP. Docs: https://developers.portone.io/opi/ko/integration/webhook
locals {
  portone_webhook_ips = toset([
    "52.78.5.241",
  ])
}

resource "cloudflare_access_rule" "portone_webhook" {
  for_each = local.portone_webhook_ips

  zone_id = data.cloudflare_zone.this.zone_id
  mode    = "whitelist"

  configuration = {
    target = "ip"
    value  = each.value
  }

  notes = "PortOne V2 webhook ${each.value} - bypass Bot Fight Mode"
}

output "portone_webhook_allowed_ips" {
  description = "Source IPs allow-listed (Bot Fight Mode bypass) for PortOne V2 webhooks."
  value       = keys(cloudflare_access_rule.portone_webhook)
}
