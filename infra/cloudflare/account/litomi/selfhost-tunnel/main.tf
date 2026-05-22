terraform {
  cloud {
    organization = "litomi"

    workspaces {
      project = "cloudflare"
      name    = "account-selfhost-tunnel"
    }
  }

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
  default     = "litomi.in"
  nullable    = false
}

locals {
  selfhost_tunnel_name           = "litomi-selfhost"
  selfhost_origin_service        = "http://traefik.kube-system.svc.cluster.local:80"
  selfhost_anal_hostname         = "anal.${var.domain}"
  selfhost_anal_preview_hostname = "anal-preview.${var.domain}"
  selfhost_img_hostname          = "img.${var.domain}"
  selfhost_stg_img_hostname      = "img-stg.${var.domain}"
  selfhost_prod_hostname         = var.domain
  selfhost_prod_api_hostname     = "api.${var.domain}"
  selfhost_stg_hostname          = "stg.${var.domain}"
  selfhost_stg_api_hostname      = "api-stg.${var.domain}"
  selfhost_argocd_hostname       = "argocd.${var.domain}"
  selfhost_grafana_hostname      = "grafana.${var.domain}"
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "selfhost" {
  account_id = var.account_id
  name       = local.selfhost_tunnel_name
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "selfhost" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.selfhost.id

  config = {
    ingress = [
      {
        hostname = local.selfhost_anal_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_anal_preview_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_img_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_stg_img_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_prod_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_prod_api_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_stg_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_stg_api_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_argocd_hostname
        service  = local.selfhost_origin_service
      },
      {
        hostname = local.selfhost_grafana_hostname
        service  = local.selfhost_origin_service
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

output "selfhost_tunnel_id" {
  description = "Cloudflare Tunnel ID for the self-hosted Litomi ingress.."
  value       = cloudflare_zero_trust_tunnel_cloudflared.selfhost.id
}

output "selfhost_tunnel_cname" {
  description = "CNAME target for DNS records routed through the self-hosted tunnel."
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.selfhost.id}.cfargotunnel.com"
}
