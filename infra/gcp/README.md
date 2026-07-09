# GCP Infrastructure

The **source proxy** (`apps/proxy` in the `litomi` repo) on Cloud Run, managed by
HCP Terraform (org `litomi`, project `gcp`). It runs VPC-unconnected so egress
rotates across Google's dynamic IP pool — the manga sources block by IP. Deployed
to two independent GCP accounts (separate IP pools / regions); the web app splits
routes across `proxy.litomi.cc` and `proxy2.litomi.cc`.

> ⚠️ Do not attach a Serverless VPC Connector, Direct VPC egress, or Cloud NAT —
> pinning egress to a static IP gets it blocked. VPC-unconnected is the point.

## Layout

```
infra/gcp/
  image.json     # shared immutable image digest, bumped by litomi CI (all proxies pin it)
  modules/
    identity/    # WIF pool + provider, bootstrap + proxy-deployer SAs, project IAM
    proxy/       # Cloud Run service, runtime SA, GHCR pull-through cache, invoker, domain mapping
  project/       # account 1 identity root  → workspace gcp-project
  proxy/         # account 1 proxy root      → workspace gcp-proxy    (Tokyo,  proxy.litomi.cc)
  project-2/     # account 2 identity root  → workspace gcp-project-2
  proxy-2/       # account 2 proxy root      → workspace gcp-proxy-2  (Taiwan, proxy2.litomi.cc)
```

Both accounts are thin roots over the same two modules. `region`, `custom_domain`,
sizing, and `allow_unauthenticated` are module defaults / root literals; only the
sensitive ids and OTLP creds are workspace variables (this repo is public).

## Workspaces

| Path          | Workspace       | Working dir           | Scope                              |
| ------------- | --------------- | --------------------- | ---------------------------------- |
| `./project`   | `gcp-project`   | `infra/gcp/project`   | Account 1 WIF trust + deployer SAs |
| `./proxy`     | `gcp-proxy`     | `infra/gcp/proxy`     | Account 1 Cloud Run proxy          |
| `./project-2` | `gcp-project-2` | `infra/gcp/project-2` | Account 2 WIF trust + deployer SAs |
| `./proxy-2`   | `gcp-proxy-2`   | `infra/gcp/proxy-2`   | Account 2 Cloud Run proxy          |

VCS-driven: PRs plan, merges apply.

## Workspace variables

Same across an account's two workspaces (put in a per-account variable set):

| Key                              | Category  | Value                                                         |
| -------------------------------- | --------- | ------------------------------------------------------------- |
| `project_id`                     | terraform | account's GCP project id                                      |
| `project_number`                 | terraform | account's GCP project number                                  |
| `TFC_GCP_PROVIDER_AUTH`          | env       | `true`                                                        |
| `TFC_GCP_WORKLOAD_PROVIDER_NAME` | env       | identity workspace's `workload_identity_provider_name` output |

Per workspace (differs — keep out of the shared set):

| Key                                 | Category              | Value                                                                                 |
| ----------------------------------- | --------------------- | ------------------------------------------------------------------------------------- |
| `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL` | env                   | identity ws → `tf-gcp-bootstrap@<project>...`, proxy ws → `tf-gcp-proxy@<project>...` |
| `otel_exporter_otlp_endpoint`       | terraform (sensitive) | Grafana Cloud OTLP gateway — proxy ws only                                            |
| `otel_exporter_otlp_headers`        | terraform (sensitive) | OTLP auth header — proxy ws only                                                      |

## Bootstrap a new account

The identity workspace must federate against a WIF pool it hasn't created yet, so
seed once out of band. If the account has **no org policy blocking SA keys** (bare
account with no organization), the temp-key path is simplest:

```bash
gcloud config set project <PROJECT_ID>
gcloud iam service-accounts create tf-seed --display-name="temp bootstrap"
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:tf-seed@<PROJECT_ID>.iam.gserviceaccount.com" \
  --role=roles/owner --condition=None
gcloud iam service-accounts keys create /tmp/tf-seed.json \
  --iam-account="tf-seed@<PROJECT_ID>.iam.gserviceaccount.com"
```

On the `gcp-project-N` workspace:

1. Set `project_id` / `project_number`, and env var `GOOGLE_CREDENTIALS` =
   `jq -c . /tmp/tf-seed.json` output (sensitive, single line). Do **not** set the
   `TFC_GCP_*` vars yet.
2. Apply → creates the WIF pool/provider, `tf-gcp-bootstrap` + `tf-gcp-proxy` SAs,
   and IAM.
3. Remove `GOOGLE_CREDENTIALS`; add the `TFC_GCP_*` vars (identity SA =
   `tf-gcp-bootstrap@...`). Plan must be a no-op.
4. `gcloud iam service-accounts delete tf-seed@<PROJECT_ID>.iam.gserviceaccount.com --quiet`

If keys are blocked, instead hand-create the WIF pool + provider + `tf-gcp-bootstrap`
SA (roles: `resourcemanager.projectIamAdmin`, `iam.serviceAccountAdmin`,
`iam.workloadIdentityPoolAdmin`, `serviceusage.serviceUsageAdmin`) and its
`workloadIdentityUser` binding for workspace `gcp-project-N`, then apply with the
`TFC_GCP_*` vars from the start.

## First proxy apply per account

`gcp-proxy-N` needs no key — it impersonates the `tf-gcp-proxy` SA the identity
workspace created. Before/at apply:

1. Set its variables (table above), with `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL =
tf-gcp-proxy@<PROJECT_ID>...` and the two OTLP secrets.
2. **Verify the domain**: add `tf-gcp-proxy@<PROJECT_ID>.iam.gserviceaccount.com`
   as an owner of the `litomi.cc` property in Google Search Console, or the domain
   mapping fails `Caller is not authorized to administer the domain`.
3. Ensure the hostname's Cloudflare `CNAME → ghs.googlehosted.com` is live (gray is
   fine for cert issuance).
4. Apply. If the Artifact Registry reader IAM fails with `service account does not
exist` (Run service agent not propagated yet), re-apply.

The image is pinned from the shared `image.json`, so the first apply works without
waiting for a new CI build.

## Image promotion

`litomi` CI builds `ghcr.io/litomi2026/litomi-proxy` (linux/amd64) on each `main`
build and opens a PR here bumping `infra/gcp/image.json` `.digest`. Both proxy
roots read that one file via `jsondecode(file("../image.json"))`, so all accounts
stay on the same immutable digest. CI holds no GCP credentials.

The GHCR package must be **Public** — each account's Artifact Registry pull-through
cache fetches it (Cloud Run cannot pull `ghcr.io` directly, and has no private
third-party registry auth). Set once: GitHub → Packages → `litomi-proxy` → Package
settings → Change visibility → Public.

## Cloudflare

Per proxy hostname (in `infra/cloudflare`):

- Proxied `CNAME → ghs.googlehosted.com` (`dns/main.tf`) — the domain mapping serves
  a Google-managed cert, so Cloudflare needs no Host/SNI override.
- In the cache ruleset `respect_origin_hostnames` (`rulesets/cache`) so Cloudflare
  absorbs the `/api/proxy/*` reads.
- SSL/TLS `strict`; each account's mapping issues its own cert.

The Cloud Run hosts are intentionally not in the Vercel hosts' Turnstile WAF gate
(`rulesets/waf-custom` `edge_proxy_host_expression_set`); add them there only if you
want that anti-abuse gate (UX/security tradeoff, not required for routing).
