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
  description = "Cloudflare zone ID for litomi.in."
  type        = string
  nullable    = false
}

variable "domain" {
  description = "Primary Cloudflare zone name."
  type        = string
  default     = "litomi.in"
  nullable    = false
}

data "terraform_remote_state" "selfhost_tunnel" {
  backend = "remote"

  config = {
    organization = "litomi"

    workspaces = {
      name = "account-selfhost-tunnel"
    }
  }
}

locals {
  selfhost_tunnel_cname      = data.terraform_remote_state.selfhost_tunnel.outputs.selfhost_tunnel_cname
  selfhost_anal_hostname     = "anal.${var.domain}"
  selfhost_anal_preview_host = "anal-preview.${var.domain}"
  selfhost_img_hostname      = "img.${var.domain}"
  selfhost_stg_img_hostname  = "img-stg.${var.domain}"
  selfhost_prod_hostname     = var.domain
  selfhost_stg_hostname      = "stg.${var.domain}"
  selfhost_argocd_hostname   = "argocd.${var.domain}"
  selfhost_grafana_hostname  = "grafana.${var.domain}"
}

resource "cloudflare_dns_record" "selfhost_root_cname" {
  zone_id = var.zone_id
  name    = local.selfhost_prod_hostname
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "selfhost_anal_cname" {
  zone_id = var.zone_id
  name    = local.selfhost_anal_hostname
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "selfhost_anal_preview_cname" {
  zone_id = var.zone_id
  name    = local.selfhost_anal_preview_host
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "www_cname" {
  zone_id = var.zone_id
  name    = "www.${var.domain}"
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "stg_cname" {
  zone_id = var.zone_id
  name    = local.selfhost_stg_hostname
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "img_cname" {
  zone_id = var.zone_id
  name    = local.selfhost_img_hostname
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "img_stg_cname" {
  zone_id = var.zone_id
  name    = local.selfhost_stg_img_hostname
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "selfhost_grafana_cname" {
  zone_id = var.zone_id
  name    = local.selfhost_grafana_hostname
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "selfhost_argocd_cname" {
  zone_id = var.zone_id
  name    = local.selfhost_argocd_hostname
  type    = "CNAME"
  content = local.selfhost_tunnel_cname
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "r2_cname" {
  zone_id = var.zone_id
  name    = "r2.${var.domain}"
  type    = "CNAME"
  content = "public.r2.dev"
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

resource "cloudflare_dns_record" "vercel2_cname" {
  zone_id = var.zone_id
  name    = "vercel2.${var.domain}"
  type    = "CNAME"
  content = "55c4083f74bdeeda.vercel-dns-016.com"
  ttl     = 600
  proxied = true
}

resource "cloudflare_dns_record" "vercel_stg_cname" {
  zone_id = var.zone_id
  name    = "vercel-stg.${var.domain}"
  type    = "CNAME"
  content = "bc90fad8422c6ce5.vercel-dns-017.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "vercel2_stg_cname" {
  zone_id = var.zone_id
  name    = "vercel2-stg.${var.domain}"
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
  content = "\"vc-domain-verify=vercel2.${var.domain},4c27109d593e9215186d,dc\""
  ttl     = 600
  proxied = false
}

resource "cloudflare_dns_record" "vercel_stg_verification_txt" {
  zone_id = var.zone_id
  name    = "_vercel"
  type    = "TXT"
  content = "\"vc-domain-verify=vercel2-stg.${var.domain},4856999ad01d6e1721c6\""
  ttl     = 3600
  proxied = false
}
