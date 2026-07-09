# GCP Infrastructure

Google Cloud is managed through HCP Terraform in the `litomi` organization and
the `gcp` project. The repository is the desired-state source; Cloud Console
changes are break-glass only and must be reconciled back into Terraform
immediately.

The only GCP workload is the **source proxy** (`apps/proxy` in the `litomi`
repo): a Bun/Hono service that fans out to the manga sources. It runs on Cloud Run
specifically so its **egress rotates across Google's dynamic IP pool** — the
sources rate-limit/block by IP.

It is deployed to **two independent GCP accounts** so their egress draws from
separate IP pools (and separate regions), and the `litomi` web app spreads source
traffic across both origins (`proxy.litomi.cc`, `proxy2.litomi.cc`). Adding an
account is a new pair of workspaces + a runbook of out-of-band bootstrap steps —
no module changes.

> ⚠️ **Do not attach a Serverless VPC Connector, Direct VPC egress, or Cloud NAT.**
> The moment egress is pinned to a static IP the sources block it. VPC-unconnected
> (the default) is the whole point.

## Layout

```
infra/gcp/
  image.json          # shared immutable image digest, bumped by litomi CI (both proxies pin it)
  modules/
    identity/         # WIF pool + provider, bootstrap + proxy-deployer SAs, project IAM
    proxy/            # Cloud Run service, runtime SA, GHCR pull-through cache, public invoker, domain mapping
  project/            # account 1 identity root  → workspace gcp-project
  proxy/              # account 1 proxy root      → workspace gcp-proxy      (Tokyo,  proxy.litomi.cc)
  project-2/          # account 2 identity root  → workspace gcp-project-2
  proxy-2/            # account 2 proxy root      → workspace gcp-proxy-2    (Taiwan, proxy2.litomi.cc)
```

Both accounts are thin roots over the same two modules; only the sensitive ids
(project id/number, OTLP creds — HCP workspace variables) and a few literals
(region, custom domain, workspace-trust names) differ. Non-secret per-account
config lives in the root; secrets never touch this public repo.

## Workspaces

| Repository path | HCP Terraform workspace | Scope |
| --------------- | ----------------------- | ----- |
| `./project`     | `gcp-project`           | Account 1 WIF trust + deployer SAs (privileged bootstrap) |
| `./proxy`       | `gcp-proxy`             | Account 1 Cloud Run proxy (Tokyo, `proxy.litomi.cc`) |
| `./project-2`   | `gcp-project-2`         | Account 2 WIF trust + deployer SAs (privileged bootstrap) |
| `./proxy-2`     | `gcp-proxy-2`           | Account 2 Cloud Run proxy (Taiwan, `proxy2.litomi.cc`) |

Each workspace uses VCS-driven runs: pull requests produce speculative plans;
merges to the production branch apply. The proxy image digest is promoted by the
`litomi` CI as a PR to this repo (see "Image Promotion"), so with **auto-apply**
on the `gcp-proxy*` workspaces proxy rollouts are hands-off (the same effect Argo
CD self-heal gives the OKE workloads). Leave it on manual apply for an approval
gate per rollout.

The two `identity` (`project`/`project-2`) roots share the same module and are
independent per account; renaming the module addresses is done with `moved` blocks
so the first apply after the module extraction is address-only (zero resource
churn — the speculative plan on the PR must show 0 to add/destroy).

## Provider Authentication

Each workspace authenticates with **HCP Terraform dynamic provider credentials**
(OIDC workload identity federation, no static keys). The `identity` module in each
account owns the trust: a Workload Identity Pool + provider that trusts HCP
Terraform's issuer, gated to this HCP organization, plus per-workspace deployer
SAs. Each proxy/identity workspace impersonates its own scoped deployer SA via
these `TFC_GCP_*` workspace environment variables:

| Env var | Value |
| ------- | ----- |
| `TFC_GCP_PROVIDER_AUTH` | `true` |
| `TFC_GCP_WORKLOAD_PROVIDER_NAME` | the account's `workload_identity_provider_name` output |
| `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL` | the workspace's deployer SA (bootstrap SA for identity, proxy-deployer SA for proxy) |

The `identity` workspace runs as the privileged bootstrap SA it also manages;
`prevent_destroy` on the root-of-trust resources stops a bad plan from revoking
its own access.

### Bootstrapping a brand-new account (chicken-and-egg)

The `identity` workspace federates against a pool it hasn't created yet on the
very first run. Break-glass once, out of band, in the new account's project:
create the WIF pool + provider and the bootstrap SA by hand (or with a temporary
user credential), grant the bootstrap SA `roles/resourcemanager.projectIamAdmin`,
`roles/iam.serviceAccountAdmin`, `roles/iam.workloadIdentityPoolAdmin`,
`roles/serviceusage.serviceUsageAdmin`, and bind it to the identity workspace
name. Then set the `TFC_GCP_*` vars and let the workspace adopt the resources
(they carry `prevent_destroy`, so a matching import/adoption — not recreation — is
expected). Account 1 is already past this.

## Workspace Variables

Per proxy workspace (`gcp-proxy`, `gcp-proxy-2`):

| Category  | Key | Sensitive | Notes |
| --------- | --- | --------- | ----- |
| Terraform | `project_id` | No* | Target GCP project id |
| Terraform | `project_number` | No* | Target GCP project number |
| Terraform | `otel_exporter_otlp_endpoint` | Yes | Grafana Cloud OTLP gateway |
| Terraform | `otel_exporter_otlp_headers` | Yes | OTLP auth header |

Per identity workspace (`gcp-project`, `gcp-project-2`): `project_id`,
`project_number`.

\* Not secret, but kept as workspace variables (not committed) because this repo is
public. `region`, `custom_domain`, sizing, and `allow_unauthenticated` default in
the modules / are set as literals in the roots; override only to diverge.

## Image Promotion (CI seam)

`litomi` CI builds and pushes `ghcr.io/litomi2026/litomi-proxy` (linux/amd64,
GitHub Packages) on every `main` build, then opens a PR here bumping the **shared**
`infra/gcp/image.json` `.digest`. Both proxy roots read that one file via
`jsondecode(file("../image.json"))` and pin the container to the immutable digest,
so every account stays in lockstep on the same build. It is a plain JSON file (not
`*.tfvars`) on purpose so it survives the Terraform `.gitignore`. CI holds **no**
GCP credentials; it only builds the image and promotes the digest.

The GHCR package must be **Public** so each account's Artifact Registry
pull-through cache can fetch it (Cloud Run has no native private-third-party
registry auth). Set it once: GitHub → Packages → `litomi-proxy` → Package settings
→ Change visibility → Public.

## Cloudflare

Cloudflare fronts both proxies (see `infra/cloudflare`). Per proxy hostname:

- A proxied `CNAME` to `ghs.googlehosted.com` (`dns/main.tf`), so the Cloud Run
  domain mapping serves a Google-managed cert and Cloudflare needs no Host/SNI
  override (Enterprise-only).
- Membership in the cache ruleset `respect_origin_hostnames` (`rulesets/cache`) so
  Cloudflare — not the sources — absorbs the `/api/proxy/*` read traffic while
  honoring the proxy's own cache-control.
- SSL/TLS is `strict`; each account's domain mapping issues its own valid cert for
  its hostname.

The Vercel edge-proxy hosts additionally sit behind a Turnstile pre-clearance WAF
gate (`rulesets/waf-custom` `edge_proxy_host_expression_set`); the Cloud Run proxy
hosts are intentionally **not** in that set. If you retire Vercel and want the same
anti-abuse gate on `proxy*/…`, add both hostnames there — it is a UX/security
tradeoff, not required for routing.

## Operating Rules

- Do not run GCP changes from local `.tfvars` or `.env` files.
- Do not use local `terraform.tfstate` as an authority.
- Do not edit Terraform-managed Cloud Run resources in the Console during normal
  operations.
- If a Console change is required for break-glass recovery, import or update
  Terraform before the next normal apply.
- Prefer adding a new GCP account as a new workspace pair over expanding a broad
  shared state.

## Hardening

- **Public invoker**: `allow_unauthenticated` defaults to `true` (Cloudflare
  fronts the service). If org policy `iam.allowedPolicyMemberDomains` (Domain
  Restricted Sharing) blocks `allUsers`, either add an exception or set
  `allow_unauthenticated = false`, switch `ingress` to
  `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`, and put an authenticated token between
  Cloudflare and Cloud Run.
