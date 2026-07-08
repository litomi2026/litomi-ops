# GCP Infrastructure

Google Cloud is managed through HCP Terraform in the `litomi` organization and
the `gcp` project. The repository is the desired-state source; Cloud Console
changes are break-glass only and must be reconciled back into Terraform
immediately.

Currently the only GCP workload is the **source proxy** (`apps/proxy` in the
`litomi` repo): a Bun/Hono service that fans out to the manga sources. It runs on
Cloud Run specifically so its **egress rotates across Google's dynamic IP pool** —
the sources rate-limit/block by IP.

> ⚠️ **Do not attach a Serverless VPC Connector, Direct VPC egress, or Cloud NAT.**
> The moment egress is pinned to a static IP the sources block it. VPC-unconnected
> (the default) is the whole point.

## Workspaces

| Repository path | HCP Terraform workspace | Scope |
| --------------- | ----------------------- | ----- |
| `./proxy`       | `gcp-proxy`             | Cloud Run proxy service, its runtime SA, public invoker IAM, `run.googleapis.com` |

Each workspace uses VCS-driven runs. Pull requests produce speculative plans;
merges to the production branch apply. Because the proxy image digest is promoted
by the `litomi` CI as a PR to this repo (see "Image Promotion"), enabling
**auto-apply** on `gcp-proxy` makes proxy rollouts hands-off — the same effect
Argo CD self-heal gives the OKE workloads. Leave it on manual apply if you prefer
an approval gate per rollout.

## Provider Authentication

The `google` provider authenticates via the `GOOGLE_CREDENTIALS` **environment
variable** (a service-account key JSON), set as a sensitive variable on the `gcp`
project variable set — the same static-credential pattern the OCI and Cloudflare
domains use. It is the only credential created by hand and lives outside Git.

The bootstrap SA needs, on the target project: `roles/run.admin`,
`roles/iam.serviceAccountAdmin` (to manage the runtime SA),
`roles/resourcemanager.projectIamAdmin` (to grant the public invoker binding), and
`roles/serviceusage.serviceUsageAdmin` (to enable `run.googleapis.com`).

Graduation path: replace the static key with **HCP Terraform dynamic provider
credentials** (workload identity federation between HCP Terraform and GCP) once a
second GCP workspace justifies the extra bootstrap.

## Workspace Variables

Project-level variable set (`gcp` project):

| Category    | Key                  | Sensitive | Notes |
| ----------- | -------------------- | --------- | ----- |
| Environment | `GOOGLE_CREDENTIALS` | Yes       | Bootstrap SA key JSON for provider auth |

`gcp-proxy` workspace variables:

| Category  | Key          | Sensitive | Notes |
| --------- | ------------ | --------- | ----- |
| Terraform | `project_id` | No        | Target GCP project id |

All other inputs (`region`, `service_name`, sizing, `allow_unauthenticated`)
default in `variables.tf`; override only to diverge.

## Image Promotion (CI seam)

`litomi` CI builds and pushes `ghcr.io/litomi2026/litomi-proxy` (linux/amd64,
GitHub Packages) on every `main` build, then opens a PR here bumping
`proxy/image.json` `.digest`. Terraform reads that file via
`jsondecode(file("image.json"))` and pins the container to the immutable digest —
it is a plain JSON file (not `*.tfvars`) on purpose so it survives the Terraform
`.gitignore`. CI holds **no** GCP credentials; it only builds the image and
promotes the digest. HCP Terraform is the only thing that touches GCP.

The GHCR package must be **Public** so Cloud Run can pull it (Cloud Run has no
native private-third-party-registry auth). Set it once after the first push:
GitHub → Packages → `litomi-proxy` → Package settings → Change visibility → Public.

## Bootstrap (one-time, out-of-band)

1. Create the `gcp` HCP Terraform project and the `gcp-proxy` workspace
   (VCS-connected to this repo, working directory `infra/gcp/proxy`).
2. Create the bootstrap SA in the GCP project with the roles listed above,
   download a key, and set it as the `GOOGLE_CREDENTIALS` project variable.
3. Set the `project_id` workspace variable.
4. Merge a `litomi` `main` build so CI publishes the first image and opens the
   `proxy/image.json` promotion PR; merge that PR (this replaces the placeholder
   digest — do not apply against the all-zeros placeholder).
5. Apply `gcp-proxy`. It enables `run.googleapis.com`, creates the runtime SA and
   the Cloud Run service, and grants the public invoker binding.
6. Point the Cloudflare Origin Rule for the proxy hostname at the `service_uri`
   output (Cloud Run routes by Host header), and keep the `/api/proxy/*` Cache
   Rule so Cloudflare — not the sources — absorbs the read traffic.

## Operating Rules

- Do not run GCP changes from local `.tfvars` or `.env` files.
- Do not use local `terraform.tfstate` as an authority.
- Do not edit Terraform-managed Cloud Run resources in the Console during normal
  operations.
- If a Console change is required for break-glass recovery, import or update
  Terraform before the next normal apply.
- Prefer adding a new GCP workload as a new workspace over expanding a broad
  shared state.

## Hardening

- **Public invoker**: `allow_unauthenticated` defaults to `true` (Cloudflare
  fronts the service). If org policy `iam.allowedPolicyMemberDomains` (Domain
  Restricted Sharing) blocks `allUsers`, either add an exception or set
  `allow_unauthenticated = false`, switch `ingress` to
  `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`, and put an authenticated token between
  Cloudflare and Cloud Run.
