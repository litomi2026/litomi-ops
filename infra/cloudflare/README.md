# Cloudflare Infrastructure

Cloudflare is managed through HCP Terraform in the `litomi` organization and
the `cloudflare` project. The repository is the desired-state source; Cloudflare
Dashboard changes are break-glass only and must be reconciled back into
Terraform immediately.

## Workspaces

| Repository path                                       | HCP Terraform workspace                                   | Scope                               |
| ----------------------------------------------------- | --------------------------------------------------------- | ----------------------------------- |
| `infra/cloudflare/account/litomi/selfhost-tunnel`     | `litomi-cloudflare-account-selfhost-tunnel`               | Account-level Cloudflare Tunnel     |
| `infra/cloudflare/account/litomi/access`              | `litomi-cloudflare-account-access`                        | Account-level Access app and policy |
| `infra/cloudflare/zone/litomi.in/dns`                 | `litomi-cloudflare-zone-litomi-in-dns`                    | Zone DNS records                    |
| `infra/cloudflare/zone/litomi.in/rulesets/cache`      | `litomi-cloudflare-zone-litomi-in-rulesets-cache`         | Cache Rules phase                   |
| `infra/cloudflare/zone/litomi.in/rulesets/rate-limit` | `litomi-cloudflare-zone-litomi-in-rulesets-rate-limiting` | Rate limiting phase                 |
| `infra/cloudflare/zone/litomi.in/rulesets/redirects`  | `litomi-cloudflare-zone-litomi-in-rulesets-redirects`     | Dynamic redirects phase             |
| `infra/cloudflare/zone/litomi.in/managed-transforms`  | `litomi-cloudflare-zone-litomi-in-managed-transforms`     | Managed transforms                  |

Each workspace should use VCS-driven runs with manual apply. Pull requests
should produce speculative plans; merges to the production branch should require
an explicit apply approval in HCP Terraform.

## Workspace Variables

Create a project-level variable set for provider credentials:

| Category    | Key                    | Sensitive | Notes                              |
| ----------- | ---------------------- | --------- | ---------------------------------- |
| Environment | `CLOUDFLARE_API_TOKEN` | Yes       | Cloudflare provider authentication |

Create a workspace-scoped variable set for account-level workspaces:

| Category  | Key          | Sensitive | Notes                                             |
| --------- | ------------ | --------- | ------------------------------------------------- |
| Terraform | `account_id` | No        | Apply to `litomi-cloudflare-account-*` workspaces |

Create a workspace-scoped variable set for the `litomi.in` zone workspaces:

| Category  | Key       | Sensitive | Notes                                                    |
| --------- | --------- | --------- | -------------------------------------------------------- |
| Terraform | `zone_id` | No        | Apply to `litomi-cloudflare-zone-litomi-in-*` workspaces |

Set `access_allowed_emails` as a workspace-specific Terraform variable on
`litomi-cloudflare-account-access`. It must be a non-empty HCL list, for example:

```hcl
["you@example.com"]
```

The Access configuration intentionally fails closed when this list is empty.

## Cross-Workspace Dependency

`zone/litomi.in/dns` reads `selfhost_tunnel_cname` from
`litomi-cloudflare-account-selfhost-tunnel` via `terraform_remote_state`.
Allow the DNS workspace to read the tunnel workspace state outputs in HCP
Terraform before planning DNS. Prefer granting this to the DNS workspace only,
not global remote-state access.

## Initial Cutover

Do not apply an empty HCP Terraform workspace against existing Cloudflare
resources. Import the current Cloudflare resources into the matching workspace
state first, then run a plan and confirm it is either empty or intentionally
small before approval.

Temporary `imports.tf` files are checked in during cutover. They should be
removed after the matching workspace successfully imports its resources and the
follow-up plan is clean.

## Operating Rules

- Do not run Cloudflare changes from local `.tfvars` or `.env` files.
- Do not use local `terraform.tfstate` as an authority.
- Do not edit Cloudflare resources in the dashboard during normal operations.
- If a dashboard change is required for break-glass recovery, import or update
  Terraform before the next normal apply.
- Prefer adding a new product or phase as a new workspace instead of expanding a
  broad shared state.
