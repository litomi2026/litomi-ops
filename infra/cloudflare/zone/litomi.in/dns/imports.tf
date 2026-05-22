data "cloudflare_dns_record" "selfhost_root_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = var.domain }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "selfhost_anal_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "anal.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "selfhost_anal_preview_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "anal-preview.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "www_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "www.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "api_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "api.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "stg_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "stg.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "api_stg_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "api-stg.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "img_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "img.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "img_stg_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "img-stg.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "selfhost_grafana_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "grafana.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "selfhost_argocd_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "argocd.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "r2_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "r2.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "vercel_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "vercel.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "vercel2_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "vercel2.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "vercel_stg_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "vercel-stg.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "vercel2_stg_cname" {
  zone_id = var.zone_id
  filter = {
    name = { exact = "vercel2-stg.${var.domain}" }
    type = "CNAME"
  }
}

data "cloudflare_dns_record" "caa" {
  zone_id = var.zone_id
  filter = {
    name = { exact = var.domain }
    type = "CAA"
  }
}

data "cloudflare_dns_record" "dmarc_txt" {
  zone_id = var.zone_id
  filter = {
    name    = { exact = "_dmarc.${var.domain}" }
    type    = "TXT"
    content = { contains = "DMARC1" }
  }
}

data "cloudflare_dns_record" "domainkey_txt" {
  zone_id = var.zone_id
  filter = {
    name    = { exact = "*._domainkey.${var.domain}" }
    type    = "TXT"
    content = { contains = "DKIM1" }
  }
}

data "cloudflare_dns_record" "spf_txt" {
  zone_id = var.zone_id
  filter = {
    name    = { exact = var.domain }
    type    = "TXT"
    content = { contains = "v=spf1 -all" }
  }
}

data "cloudflare_dns_record" "google_verification_txt" {
  zone_id = var.zone_id
  filter = {
    name    = { exact = var.domain }
    type    = "TXT"
    content = { contains = "google-site-verification=9lwchIN7Iw35PvdxZPPW-QFktzJY1q_SP4llbtlVej4" }
  }
}

data "cloudflare_dns_record" "vercel_verification_txt" {
  zone_id = var.zone_id
  filter = {
    name    = { exact = "_vercel.${var.domain}" }
    type    = "TXT"
    content = { contains = "vc-domain-verify=vercel2.${var.domain},4c27109d593e9215186d" }
  }
}

data "cloudflare_dns_record" "vercel_stg_verification_txt" {
  zone_id = var.zone_id
  filter = {
    name    = { exact = "_vercel.${var.domain}" }
    type    = "TXT"
    content = { contains = "vc-domain-verify=vercel2-stg.${var.domain},4856999ad01d6e1721c6" }
  }
}

import {
  to = cloudflare_dns_record.selfhost_root_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.selfhost_root_cname.id}"
}

import {
  to = cloudflare_dns_record.selfhost_anal_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.selfhost_anal_cname.id}"
}

import {
  to = cloudflare_dns_record.selfhost_anal_preview_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.selfhost_anal_preview_cname.id}"
}

import {
  to = cloudflare_dns_record.www_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.www_cname.id}"
}

import {
  to = cloudflare_dns_record.api_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.api_cname.id}"
}

import {
  to = cloudflare_dns_record.stg_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.stg_cname.id}"
}

import {
  to = cloudflare_dns_record.api_stg_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.api_stg_cname.id}"
}

import {
  to = cloudflare_dns_record.img_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.img_cname.id}"
}

import {
  to = cloudflare_dns_record.img_stg_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.img_stg_cname.id}"
}

import {
  to = cloudflare_dns_record.selfhost_grafana_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.selfhost_grafana_cname.id}"
}

import {
  to = cloudflare_dns_record.selfhost_argocd_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.selfhost_argocd_cname.id}"
}

import {
  to = cloudflare_dns_record.r2_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.r2_cname.id}"
}

import {
  to = cloudflare_dns_record.vercel_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.vercel_cname.id}"
}

import {
  to = cloudflare_dns_record.vercel2_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.vercel2_cname.id}"
}

import {
  to = cloudflare_dns_record.vercel_stg_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.vercel_stg_cname.id}"
}

import {
  to = cloudflare_dns_record.vercel2_stg_cname
  id = "${var.zone_id}/${data.cloudflare_dns_record.vercel2_stg_cname.id}"
}

import {
  to = cloudflare_dns_record.caa
  id = "${var.zone_id}/${data.cloudflare_dns_record.caa.id}"
}

import {
  to = cloudflare_dns_record.dmarc_txt
  id = "${var.zone_id}/${data.cloudflare_dns_record.dmarc_txt.id}"
}

import {
  to = cloudflare_dns_record.domainkey_txt
  id = "${var.zone_id}/${data.cloudflare_dns_record.domainkey_txt.id}"
}

import {
  to = cloudflare_dns_record.spf_txt
  id = "${var.zone_id}/${data.cloudflare_dns_record.spf_txt.id}"
}

import {
  to = cloudflare_dns_record.google_verification_txt
  id = "${var.zone_id}/${data.cloudflare_dns_record.google_verification_txt.id}"
}

import {
  to = cloudflare_dns_record.vercel_verification_txt
  id = "${var.zone_id}/${data.cloudflare_dns_record.vercel_verification_txt.id}"
}

import {
  to = cloudflare_dns_record.vercel_stg_verification_txt
  id = "${var.zone_id}/${data.cloudflare_dns_record.vercel_stg_verification_txt.id}"
}
