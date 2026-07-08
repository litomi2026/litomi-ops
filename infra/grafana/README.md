# Grafana Cloud Infrastructure

Grafana Cloud is managed through HCP Terraform in the `litomi` organization and
the `grafana` project. The repository is the desired-state source; Grafana UI
changes are break-glass only and must be reconciled back into Terraform
immediately.

Terraform owns the Grafana Cloud **configuration**: the stack, access policies
and their tokens, stack service accounts, alerting (contact points, notification
policy, custom rules), custom folders, and custom dashboards. The telemetry
**collection** path (Alloy agents) stays in `k8s/platform/grafana-k8s-monitoring`
because it runs inside the OKE cluster and is delivered by Argo CD.

## Not Managed by Terraform

Only the content an app **auto-provisions** is off-limits — importing it produces
permanent drift:

- Asserts, Synthetic Monitoring, k6, App Observability, and GrafanaCloud
  usage/billing dashboards.
- `integrations-kubernetes` and other integration-shipped alert/recording rules.

The config **you** set inside those apps is a different layer and is managed
here: Synthetic Monitoring **checks**, the Frontend Observability **app**, SLOs,
custom alerting, and custom dashboards. App Observability and k8s Monitoring have
no discrete config resource — they render from OTLP/collectors, so nothing moves
for them beyond the collector Helm chart already in Argo CD.

## Workspaces

| Repository path | HCP Terraform workspace | Scope |
| --------------- | ----------------------- | ----- |
| `./cloud`       | `grafana-cloud`         | Org scope: stack, access policies + tokens, stack service account, Synthetic Monitoring, Frontend Observability |
| `./stack`       | `grafana-stack-prod`    | In-stack: contact points, notification policy, folders, dashboards |

The collector credential is delivered to OCI Vault by a separate OCI-domain
workspace, `oci-grafana-collector-secret` (`infra/oci/grafana-collector-secret`,
project `oci`) — see "Collector Credential Delivery" below. Keeping it out of the
Grafana workspaces means no workspace holds another domain's credentials.

Each workspace uses VCS-driven runs with manual apply. Pull requests produce
speculative plans; merges to the production branch require an explicit apply
approval in HCP Terraform.

## Provider Authentication

The `grafana/grafana` provider has two auth scopes:

- **Org scope** (`grafana-cloud` workspace): `cloud_access_policy_token`. Manages
  the stack, cloud access policies/tokens, and stack service accounts.
- **In-stack scope** (`grafana-stack-prod` workspace): the stack `url` plus an
  Admin service account token minted by the `grafana-cloud` workspace.

The `grafana-cloud` workspace runs the `grafana` provider only. It outputs the
collector credential (`collector_credentials`); the OCI Vault write happens in the
separate `oci-grafana-collector-secret` workspace.

## Bootstrap (one-time, out-of-band)

1. In the Grafana Cloud portal, create an **Access Policy token** scoped for org
   management: `stacks:read`, `stacks:write`, `accesspolicies:read`,
   `accesspolicies:write`, `stack-service-accounts:write`, plus the
   Synthetic Monitoring and Frontend Observability management scopes the portal
   lists for this stack. This is the only credential created by hand — like the
   OCI bootstrap identifiers, it lives outside Git.
2. Set it as the `grafana` project variable set key `TF_VAR_grafana_cloud_access_policy_token`.
3. `terraform apply` `grafana-cloud` — it imports the stack, mints the collector
   token, creates the stack service account token, and installs Synthetic
   Monitoring + Frontend Observability. It touches no OCI resources.
4. Attach the OCI provider-credentials variable set to
   `oci-grafana-collector-secret`, copy the OCI identifiers below into its
   variables, grant it remote-state read on `grafana-cloud`, then
   `terraform apply` it to deliver the collector credential to OCI Vault.
5. Grant `grafana-stack-prod` remote-state read on `grafana-cloud`, then
   `terraform apply` `grafana-stack-prod`.

## Workspace Variables

Project-level variable set (`grafana` project):

| Category    | Key                                     | Sensitive | Notes |
| ----------- | --------------------------------------- | --------- | ----- |
| Environment | `TF_VAR_grafana_cloud_access_policy_token` | Yes    | Org-scope bootstrap token |

`grafana-cloud` workspace variables:

| Category  | Key                                | Sensitive | Notes |
| --------- | ---------------------------------- | --------- | ----- |
| Terraform | `grafana_cloud_organization_slug`  | No        | Grafana Cloud org slug |
| Terraform | `grafana_cloud_region`             | No        | Stack region slug (must match the existing stack) |
| Terraform | `grafana_stack_slug`               | No        | Existing stack subdomain |
| Terraform | `grafana_stack_id`                 | No        | Existing stack numeric ID (import identifier) |

`oci-grafana-collector-secret` workspace variables:

| Category  | Key                             | Sensitive | Notes |
| --------- | ------------------------------- | --------- | ----- |
| Terraform | `oci_region`                    | No        | From `oci-prod` |
| Terraform | `oci_compartment_id`            | Yes       | `oci-prod` output `workload_compartment_id` |
| Terraform | `oci_vault_ocid`                | Yes       | `oci-prod` output `vault_ocid` |
| Terraform | `oci_kms_key_ocid`              | Yes       | `oci-prod` output `kms_key_ocid` |
| Terraform | `grafana_collector_secret_ocid` | Yes       | OCID of the existing secret, for import |

Plus the OCI provider-credentials variable set (`oci_tenancy_ocid`,
`oci_user_ocid`, `oci_fingerprint`, `oci_private_key`, `oci_private_key_password`),
the same one `oci-prod` uses.

`grafana-stack-prod` workspace variables:

| Category  | Key                   | Sensitive | Notes |
| --------- | --------------------- | --------- | ----- |
| Terraform | `discord_webhook_url` | Yes       | Alert delivery target |

## Cross-Workspace Dependency

Two workspaces read `grafana-cloud` outputs via `terraform_remote_state`:
`grafana-stack-prod` (stack URL + service account token) and
`oci-grafana-collector-secret` (`collector_credentials`). Grant each remote-state
read on `grafana-cloud` only — not global remote-state access.

## Collector Credential Delivery

The collector credential (`litomi-prod-grafana-cloud-k8s`) is minted by
`grafana-cloud` and delivered to OCI Vault by the `oci-grafana-collector-secret`
workspace, which reads the `collector_credentials` output and owns the
`oci_vault_secret`. Domains stay separate: the Grafana workspace never holds OCI
credentials, and the OCI workspace never holds Grafana credentials. Rotating the
token is a `grafana-cloud` apply (new token) followed by an
`oci-grafana-collector-secret` apply (writes it).

This intentionally supersedes the OCI Vault module's "content is rotated
out-of-band" rule for this one secret. That rule still holds for the DB-class
secrets (`web`/`api`/`chat`/`argocd`/`cert-manager`), where the value is
high-value and long-lived. A machine-generated, write-only, one-click-revocable
ingest token is a different risk class and is better served by full IaC with a
protected HCP Terraform backend.

One-time cutover is gap-free by adoption, not destroy/recreate. The `oci-prod`
workspace releases the secret from its state without destroying it
(`terraform state rm module.vault.oci_vault_secret.grafana_k8s_monitoring`), and
`oci-grafana-collector-secret` adopts the same secret via the `import` block in
`main.tf` (`var.grafana_collector_secret_ocid`), then updates its content to the
freshly minted token. Same name, no OCI pending-deletion collision, no collector gap.

## Dashboards

Custom dashboards are Terraform-managed: drop a dashboard JSON model into
`stack/dashboards/*.json` and it is applied by `grafana_dashboard`. This keeps a
single control plane and review flow alongside access policies and alerting.

Graduate to Grafana Git Sync only when dashboard authoring becomes high-volume
and UI-first across multiple people — at that point the bi-directional UI↔Git
workflow outweighs running a second control plane. Access policies, tokens, the
stack, and SLOs stay in Terraform regardless.

## Synthetic Monitoring

`cloud/synthetic_monitoring.tf` manages the SM installation, a dedicated
publisher access policy/token, and the checks. The installation resource cannot
be imported but applies cleanly on the already-enabled SM app.

The two existing checks (`litomi-prod-web-health` → `https://litomi.cc/health`,
`litomi-prod-api-health` → `https://litomi.cc/api/health`, Tokyo probe, 60s) are
reproduced from their live config. They were created in the UI and cannot be
imported by ID here without the SM check IDs, so the one-time cutover deletes the
two UI checks and lets Terraform recreate them — a few seconds of probe gap. Verify
finer HTTP settings (method, valid status codes) against the UI, since the metric
model does not expose them.

## Frontend Observability

`cloud/frontend_o11y.tf` registers the Faro app and exports
`frontend_o11y_collector_endpoint`. This resource cannot be cleanly imported, so
adopting it means pointing the web app's Faro SDK config at the exported
collector endpoint (a web redeploy) rather than the current UI-created app. Set
`frontend_o11y_allowed_origins` to the real site origins before apply.

## Operating Rules

- Do not run Grafana Cloud changes from local `.tfvars` or `.env` files.
- Do not use local `terraform.tfstate` as an authority.
- Do not edit Terraform-managed Grafana resources in the UI during normal
  operations.
- If a UI change is required for break-glass recovery, import or update Terraform
  before the next normal apply.
- Prefer adding a new concern as new files in the existing workspace over a broad
  shared state; add a new workspace only when a hard state boundary is needed.
