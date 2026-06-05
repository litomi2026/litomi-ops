terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

locals {
  initial_web_secret_content = base64encode(jsonencode({
    APP_POSTGRES_CERTIFICATE     = "REPLACE_ME_APP_POSTGRES_CERTIFICATE"
    APP_POSTGRES_URL             = "REPLACE_ME_APP_POSTGRES_URL"
    CATALOG_POSTGRES_CERTIFICATE = "REPLACE_ME_CATALOG_POSTGRES_CERTIFICATE"
    CATALOG_POSTGRES_URL         = "REPLACE_ME_CATALOG_POSTGRES_URL"
    JWT_SECRET_ACCESS_TOKEN      = "REPLACE_ME_JWT_SECRET_ACCESS_TOKEN"
    JWT_SECRET_REFRESH_TOKEN     = "REPLACE_ME_JWT_SECRET_REFRESH_TOKEN"
    JWT_SECRET_TRUSTED_DEVICE    = "REPLACE_ME_JWT_SECRET_TRUSTED_DEVICE"
    REDIS_URL                    = "REPLACE_ME_REDIS_URL"
    TOTP_ENCRYPTION_KEY          = "REPLACE_ME_TOTP_ENCRYPTION_KEY"
    VAPID_PUBLIC_KEY             = "REPLACE_ME_VAPID_PUBLIC_KEY"
  }))

  initial_api_secret_content = base64encode(jsonencode({
    ADSTERRA_API_KEY             = "REPLACE_ME_ADSTERRA_API_KEY"
    APP_POSTGRES_CERTIFICATE     = "REPLACE_ME_APP_POSTGRES_CERTIFICATE"
    APP_POSTGRES_URL             = "REPLACE_ME_APP_POSTGRES_URL"
    BBATON_CLIENT_SECRET         = "REPLACE_ME_BBATON_CLIENT_SECRET"
    CATALOG_POSTGRES_CERTIFICATE = "REPLACE_ME_CATALOG_POSTGRES_CERTIFICATE"
    CATALOG_POSTGRES_URL         = "REPLACE_ME_CATALOG_POSTGRES_URL"
    JWT_SECRET_ACCESS_TOKEN      = "REPLACE_ME_JWT_SECRET_ACCESS_TOKEN"
    JWT_SECRET_REFRESH_TOKEN     = "REPLACE_ME_JWT_SECRET_REFRESH_TOKEN"
    JWT_SECRET_TRUSTED_DEVICE    = "REPLACE_ME_JWT_SECRET_TRUSTED_DEVICE"
    REDIS_URL                    = "REPLACE_ME_REDIS_URL"
    TOTP_ENCRYPTION_KEY          = "REPLACE_ME_TOTP_ENCRYPTION_KEY"
    TURNSTILE_SECRET_KEY         = "REPLACE_ME_TURNSTILE_SECRET_KEY"
    VAPID_PRIVATE_KEY            = "REPLACE_ME_VAPID_PRIVATE_KEY"
  }))

  initial_argocd_secret_content = base64encode(jsonencode({
    CLOUDFLARE_ACCESS_ARGOCD_ISSUER        = "REPLACE_ME_CLOUDFLARE_ACCESS_ARGOCD_ISSUER"
    CLOUDFLARE_ACCESS_ARGOCD_CLIENT_ID     = "REPLACE_ME_CLOUDFLARE_ACCESS_ARGOCD_CLIENT_ID"
    CLOUDFLARE_ACCESS_ARGOCD_CLIENT_SECRET = "REPLACE_ME_CLOUDFLARE_ACCESS_ARGOCD_CLIENT_SECRET"
    GITHUB_WEBHOOK_SECRET                  = "REPLACE_ME_GITHUB_WEBHOOK_SECRET"
  }))

  initial_cert_manager_secret_content = base64encode(jsonencode({
    CLOUDFLARE_API_TOKEN = "REPLACE_ME_CLOUDFLARE_API_TOKEN"
  }))
}

resource "oci_kms_vault" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-vault"
  vault_type     = "DEFAULT"
  freeform_tags  = var.freeform_tags
}

resource "oci_kms_key" "this" {
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_name_prefix}-key"
  management_endpoint = oci_kms_vault.this.management_endpoint
  freeform_tags       = var.freeform_tags
  protection_mode     = "SOFTWARE"

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_vault_secret" "web" {
  compartment_id = var.compartment_id
  description    = "Secret container for the web workload. Secret values are managed out-of-band."
  key_id         = oci_kms_key.this.id
  secret_name    = var.web_secret_name
  vault_id       = oci_kms_vault.this.id
  freeform_tags  = var.freeform_tags

  secret_content {
    content      = local.initial_web_secret_content
    content_type = "BASE64"
    name         = "initial-placeholder"
    stage        = "CURRENT"
  }

  lifecycle {
    # OCI Vault secret version은 부트스트랩/로테이션 절차가 CURRENT 값을 갱신한다.
    # Terraform state에 실제 비밀값을 저장하지 않기 위한 예외이므로 GitOps drift로 보지 않는다.
    ignore_changes = [secret_content]
  }
}

resource "oci_vault_secret" "api" {
  compartment_id = var.compartment_id
  description    = "Secret container for the API workload. Secret values are managed out-of-band."
  key_id         = oci_kms_key.this.id
  secret_name    = var.api_secret_name
  vault_id       = oci_kms_vault.this.id
  freeform_tags  = var.freeform_tags

  secret_content {
    content      = local.initial_api_secret_content
    content_type = "BASE64"
    name         = "initial-placeholder"
    stage        = "CURRENT"
  }

  lifecycle {
    # OCI Vault secret version은 부트스트랩/로테이션 절차가 CURRENT 값을 갱신한다.
    # Terraform state에 실제 비밀값을 저장하지 않기 위한 예외이므로 GitOps drift로 보지 않는다.
    ignore_changes = [secret_content]
  }
}

resource "oci_vault_secret" "argocd" {
  compartment_id = var.compartment_id
  description    = "Secret container for Argo CD. Secret values are managed out-of-band."
  key_id         = oci_kms_key.this.id
  secret_name    = var.argocd_secret_name
  vault_id       = oci_kms_vault.this.id
  freeform_tags  = var.freeform_tags

  secret_content {
    content      = local.initial_argocd_secret_content
    content_type = "BASE64"
    name         = "initial-placeholder"
    stage        = "CURRENT"
  }

  lifecycle {
    # OCI Vault secret version은 Argo CD 부트스트랩/로테이션 절차가 CURRENT 값을 갱신한다.
    # Terraform state에 실제 Argo CD 비밀값을 저장하지 않기 위한 예외이므로 GitOps drift로 보지 않는다.
    ignore_changes = [secret_content]
  }
}

resource "oci_vault_secret" "cert_manager" {
  compartment_id = var.compartment_id
  description    = "Secret container for cert-manager. Secret values are managed out-of-band."
  key_id         = oci_kms_key.this.id
  secret_name    = var.cert_manager_secret_name
  vault_id       = oci_kms_vault.this.id
  freeform_tags  = var.freeform_tags

  secret_content {
    content      = local.initial_cert_manager_secret_content
    content_type = "BASE64"
    name         = "initial-placeholder"
    stage        = "CURRENT"
  }

  lifecycle {
    # OCI Vault secret version은 cert-manager 부트스트랩/로테이션 절차가 CURRENT 값을 갱신한다.
    # Terraform state에 실제 Cloudflare API token을 저장하지 않기 위한 예외이므로 GitOps drift로 보지 않는다.
    ignore_changes = [secret_content]
  }
}
