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

data "cloudflare_zone" "this" {
  filter = {
    name = var.domain
  }
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

  zone_id = data.cloudflare_zone.this.zone_id
  name    = each.value
  type    = "A"
  content = var.oke_edge_ipv4
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "www_cname" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "www.${var.domain}"
  type    = "CNAME"
  content = var.domain
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "proxy_cname" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "proxy.${var.domain}"
  type    = "CNAME"
  content = "ghs.googlehosted.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "proxy2_cname" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "proxy2.${var.domain}"
  type    = "CNAME"
  content = "ghs.googlehosted.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "caa" {
  zone_id = data.cloudflare_zone.this.zone_id
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
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s; rua=mailto:2f5f6900562c4b2b93de27531f70eb4e@dmarc-reports.cloudflare.net;\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "domainkey_txt" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "*._domainkey.${var.domain}"
  type    = "TXT"
  content = "\"v=DKIM1; p=\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "spf_txt" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = var.domain
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "google_verification_txt" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = var.domain
  type    = "TXT"
  content = "\"google-site-verification=9lwchIN7Iw35PvdxZPPW-QFktzJY1q_SP4llbtlVej4\""
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "google_verification2_txt" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = var.domain
  type    = "TXT"
  content = "\"google-site-verification=btUSc6zsZBn_G2Wt8evVcQ-5yaCM5uIQlBFIoFw-Hpk\""
  ttl     = 3600
  proxied = false
}

resource "cloudflare_zone_dnssec" "litomi_cc" {
  zone_id = data.cloudflare_zone.this.zone_id
  status  = "active"
}
