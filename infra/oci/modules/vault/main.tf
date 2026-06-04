terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

locals {
  initial_workload_secret_content = base64encode(jsonencode({
    DATABASE_URL        = "REPLACE_ME_DATABASE_URL"
    BETTER_AUTH_SECRETS = "REPLACE_ME_BETTER_AUTH_SECRETS"
  }))
  initial_argocd_secret_content = base64encode(jsonencode({
    CLOUDFLARE_ACCESS_ARGOCD_CLIENT_SECRET = "REPLACE_ME_CLOUDFLARE_ACCESS_ARGOCD_CLIENT_SECRET"
    GITHUB_WEBHOOK_SECRET                  = "REPLACE_ME_GITHUB_WEBHOOK_SECRET"
    GITHUB_APP_ID                          = "REPLACE_ME_GITHUB_APP_ID"
    GITHUB_APP_INSTALLATION_ID             = "REPLACE_ME_GITHUB_APP_INSTALLATION_ID"
    GITHUB_APP_PRIVATE_KEY                 = "REPLACE_ME_GITHUB_APP_PRIVATE_KEY"
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
    content      = local.initial_workload_secret_content
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
    content      = local.initial_workload_secret_content
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
