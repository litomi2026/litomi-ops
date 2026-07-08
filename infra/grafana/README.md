# Grafana Cloud Infrastructure

Grafana Cloud is managed through HCP Terraform in the `litomi` organization. The
repository is the source of truth; UI changes are break-glass only and must be
reconciled back into Terraform.

Terraform owns the Grafana Cloud **configuration**: the stack, access policies and
tokens, the stack service account, alerting (contact points, notification policy,
SLOs), Synthetic Monitoring checks, the Frontend Observability app, folders, and
dashboards. Telemetry **collection** (Alloy agents) lives in
`k8s/platform/grafana-k8s-monitoring` (Argo CD), not here.

**Not managed:** content that Grafana apps auto-provision — Asserts / Synthetic
Monitoring / k6 / App Observability dashboards, and integration-shipped
alert/recording rules. Importing them causes permanent drift.

## Workspaces

| Path                               | HCP workspace                  | Project   | Scope                                                                                                |
| ---------------------------------- | ------------------------------ | --------- | ---------------------------------------------------------------------------------------------------- |
| `cloud/`                           | `grafana-cloud`                | `grafana` | Stack, access policies + tokens, stack service account, Synthetic Monitoring, Frontend Observability |
| `stack/`                           | `grafana-stack-prod`           | `grafana` | Contact points, notification policy, SLOs, folders, dashboards                                       |
| `../oci/grafana-collector-secret/` | `oci-grafana-collector-secret` | `oci`     | Writes the collector credential into OCI Vault                                                       |

## Prerequisites

- A **Grafana Cloud account** (org) exists. You only need its slug and the ability
  to create an access policy token — the stack and everything else is created by
  Terraform.
- **`oci-prod` is applied.** It provides the Vault (`vault_ocid`, `kms_key_ocid`)
  and the workload compartment. The collector-secret workspace also needs the same
  OCI API credentials `oci-prod` uses.

## Setup

1. Create HCP project `grafana` and three workspaces (VCS-driven, manual apply):
   - `grafana-cloud` → working dir `infra/grafana/cloud`
   - `grafana-stack-prod` → working dir `infra/grafana/stack`
   - `oci-grafana-collector-secret` → project `oci`, working dir `infra/oci/grafana-collector-secret`
2. In the Grafana Cloud portal create an **Access Policy token** (org realm) with
   scopes `stacks:read`, `stacks:write`, `accesspolicies:read`,
   `accesspolicies:write`, `stack-service-accounts:write`, plus the Synthetic
   Monitoring and Frontend Observability scopes. Set it as a `grafana-cloud`
   workspace variable `grafana_cloud_access_policy_token` (sensitive).
3. Set `grafana-cloud` variables (below) and **apply**. It creates the stack, the
   collector token, the stack service account, Synthetic Monitoring, and the
   Frontend Observability app.
4. On `oci-grafana-collector-secret`: set the OCI provider credentials and the
   identifiers (below) as workspace variables, grant it remote-state read on
   `grafana-cloud`, and **apply**. It writes the collector credential to OCI Vault.
5. On `grafana-stack-prod`: set the Discord webhooks, grant it remote-state read on
   `grafana-cloud`, and **apply**. It creates the contact points, notification
   policy, SLOs, and folder.

## Variables

All values below are set as **workspace variables** (Terraform category).

`grafana-cloud`:

| Key                                 | Sensitive | Notes                                            |
| ----------------------------------- | --------- | ------------------------------------------------ |
| `grafana_cloud_access_policy_token` | Yes       | Bootstrap org access policy token                |
| `grafana_cloud_organization_slug`   | No        | Grafana Cloud org slug                           |
| `grafana_stack_slug`                | No        | Stack subdomain to create (`<slug>.grafana.net`) |

`oci-grafana-collector-secret`:

The OCI provider credentials (same values as `oci-prod`) plus the identifiers from `oci-prod` outputs.

| Key                    | Sensitive | Notes                                       |
| ---------------------- | --------- | ------------------------------------------- |
| `region`               | No        | OCI region, e.g. `ap-seoul-1`               |
| `tenancy_ocid`         | Yes       | OCI provider auth                           |
| `user_ocid`            | Yes       | OCI provider auth                           |
| `fingerprint`          | Yes       | OCI provider auth                           |
| `private_key`          | Yes       | OCI API private key (PEM)                   |
| `private_key_password` | Yes       | Optional; omit if the key has none          |
| `compartment_id`       | Yes       | `oci-prod` output `workload_compartment_id` |
| `vault_ocid`           | Yes       | `oci-prod` output `vault_ocid`              |
| `kms_key_ocid`         | Yes       | `oci-prod` output `kms_key_ocid`            |

`grafana-stack-prod`:

| Key                            | Sensitive | Notes                      |
| ------------------------------ | --------- | -------------------------- |
| `discord_critical_webhook_url` | Yes       | Critical + default channel |
| `discord_warning_webhook_url`  | Yes       | `severity=warning` channel |

## Cross-workspace remote state

`grafana-stack-prod` and `oci-grafana-collector-secret` read `grafana-cloud`
outputs via `terraform_remote_state`. In the `grafana-cloud` workspace, add both as
authorized remote state consumers — not global access.

## After apply

- **Collection:** point `k8s/platform/grafana-k8s-monitoring` at the new stack's
  ingest URLs (from the Grafana Cloud portal); its credentials come from the OCI
  Vault secret this stack fills. Restart the Alloy collector pods so they pick up
  the secret.
- **Frontend Observability:** set the web app's Faro SDK collector URL to the
  `frontend_o11y_collector_endpoint` output, then redeploy.
