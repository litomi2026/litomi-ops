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

variable "domain" {
  description = "Primary Cloudflare zone name."
  type        = string
  default     = "litomi.cc"
  nullable    = false
}

variable "oke_edge_ipv4" {
  description = "Reserved OCI public IPv4 for the production OKE edge NLB."
  type        = string
  nullable    = false
  sensitive   = true

  validation {
    condition     = can(cidrnetmask("${var.oke_edge_ipv4}/32"))
    error_message = "oke_edge_ipv4 must be a valid IPv4 address."
  }
}

locals {
  oke_edge_hostnames = {
    root   = var.domain
    img    = "img.${var.domain}"
    argocd = "argocd.${var.domain}"
  }
}

resource "cloudflare_dns_record" "oke_edge_a" {
  for_each = local.oke_edge_hostnames

  zone_id = var.zone_id
  name    = each.value
  type    = "A"
  content = var.oke_edge_ipv4
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "www_cname" {
  zone_id = var.zone_id
  name    = "www.${var.domain}"
  type    = "CNAME"
  content = var.domain
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "vercel_cname" {
  zone_id = var.zone_id
  name    = "vercel.${var.domain}"
  type    = "CNAME"
  content = "cname.vercel-dns.com"
  ttl     = 1
  proxied = true
}

# TEMPORARY: adopt the pre-existing vercel2 CNAME into state. The record lives in
# Cloudflare, but the prior state entry went stale (404 on refresh), so Terraform
# planned a create that would collide with the live record. The data source looks up
# the current record id at plan time so the import needs no hardcoded id. Remove this
# data source and the import block in a follow-up commit once the import has applied.
data "cloudflare_dns_records" "vercel2_cname" {
  zone_id   = var.zone_id
  type      = "CNAME"
  max_items = 1

  name = {
    exact = "vercel2.${var.domain}"
  }
}

import {
  to = cloudflare_dns_record.vercel2_cname
  id = "${var.zone_id}/${data.cloudflare_dns_records.vercel2_cname.result[0].id}"
}

resource "cloudflare_dns_record" "vercel2_cname" {
  zone_id = var.zone_id
  name    = "vercel2.${var.domain}"
  type    = "CNAME"
  content = "55c4083f74bdeeda.vercel-dns-016.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "caa" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "CAA"
  ttl     = 1
  proxied = false

  data = {
    flags = 0
    tag   = "issue"
    value = "letsencrypt.org"
  }
}

resource "cloudflare_dns_record" "dmarc_txt" {
  zone_id = var.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s; rua=mailto:2f5f6900562c4b2b93de27531f70eb4e@dmarc-reports.cloudflare.net;\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "domainkey_txt" {
  zone_id = var.zone_id
  name    = "*._domainkey.${var.domain}"
  type    = "TXT"
  content = "\"v=DKIM1; p=\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "spf_txt" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "google_verification_txt" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "TXT"
  content = "\"google-site-verification=9lwchIN7Iw35PvdxZPPW-QFktzJY1q_SP4llbtlVej4\""
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "vercel_verification_txt" {
  zone_id = var.zone_id
  name    = "_vercel"
  type    = "TXT"
  content = "\"vc-domain-verify=vercel2.${var.domain},317544e90c67411ab41b,dc\""
  ttl     = 600
  proxied = false
}
