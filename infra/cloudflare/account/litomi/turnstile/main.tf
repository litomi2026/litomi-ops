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
  default     = "litomi.cc"
  nullable    = false
}

locals {
  turnstile_widget_name = "litomi"

  turnstile_widget_domains = [
    var.domain,
    "stg.${var.domain}",
  ]
}

resource "cloudflare_turnstile_widget" "litomi" {
  account_id = var.account_id

  name    = local.turnstile_widget_name
  domains = local.turnstile_widget_domains
  mode    = "managed"
  region  = "world"

  bot_fight_mode  = false
  clearance_level = "managed"
  ephemeral_id    = false
  offlabel        = false
}

output "turnstile_widget_sitekey" {
  description = "Cloudflare Turnstile widget sitekey for the Litomi web application."
  value       = cloudflare_turnstile_widget.litomi.sitekey
}
