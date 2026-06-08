# Cloudflare Infrastructure

Cloudflare is managed through HCP Terraform in the `litomi` organization and
the `cloudflare` project. The repository is the desired-state source; Cloudflare
Dashboard changes are break-glass only and must be reconciled back into
Terraform immediately.

## Workspaces

| Repository path                        | HCP Terraform workspace             | Scope                               |
| -------------------------------------- | ----------------------------------- | ----------------------------------- |
| `./account/litomi/selfhost-tunnel`     | `account-selfhost-tunnel`           | Account-level Cloudflare Tunnel     |
| `./account/litomi/access`              | `account-access`                    | Account-level Access app and policy |
| `./account/litomi/turnstile`           | `account-turnstile`                 | Account-level Turnstile widget      |
| `./zone/litomi.in/dns`                 | `zone-litomi-in-dns`                | Zone DNS records                    |
| `./zone/litomi.in/bot-management`      | `zone-litomi-in-bot-management`     | Bot Management settings             |
| `./zone/litomi.in/rulesets/cache`      | `zone-litomi-in-cache`              | Cache Rules phase                   |
| `./zone/litomi.in/rulesets/rate-limit` | `zone-litomi-in-rate-limit`         | Rate limiting phase                 |
| `./zone/litomi.in/rulesets/redirects`  | `zone-litomi-in-redirects`          | Dynamic redirects phase             |
| `./zone/litomi.in/rulesets/waf-custom` | `zone-litomi-in-waf-custom`         | WAF custom rules phase              |
| `./zone/litomi.in/managed-transforms`  | `zone-litomi-in-managed-transforms` | Managed transforms                  |

Each workspace should use VCS-driven runs with manual apply. Pull requests
should produce speculative plans; merges to the production branch should require
an explicit apply approval in HCP Terraform.

## Workspace Variables

Create a project-level variable set for provider credentials:

| Category    | Key                    | Sensitive | Notes                              |
| ----------- | ---------------------- | --------- | ---------------------------------- |
| Environment | `CLOUDFLARE_API_TOKEN` | Yes       | Cloudflare provider authentication |

Create a workspace-scoped variable set for account-level workspaces:

| Category  | Key          | Sensitive | Notes                           |
| --------- | ------------ | --------- | ------------------------------- |
| Terraform | `account_id` | No        | Apply to `account-*` workspaces |

Create a workspace-scoped variable set for the `litomi.in` zone workspaces:

| Category  | Key       | Sensitive | Notes                                  |
| --------- | --------- | --------- | -------------------------------------- |
| Terraform | `zone_id` | No        | Apply to `zone-litomi-in-*` workspaces |

Set this workspace-specific Terraform variable on `zone-litomi-in-waf-custom`:

| Category  | Key                  | Sensitive | HCL | Notes                  |
| --------- | -------------------- | --------- | --- | ---------------------- |
| Terraform | `blocked_source_ips` | No        | Yes | HCL list of source IPs |

Set these workspace-specific Terraform variables on `zone-litomi-in-rate-limit`:

| Category  | Key                   | Sensitive | Notes                                     |
| --------- | --------------------- | --------- | ----------------------------------------- |
| Terraform | `rate_limit_period`   | Yes       | Rate limiting period in seconds           |
| Terraform | `rate_limit_requests` | Yes       | Maximum requests allowed per period       |
| Terraform | `rate_limit_timeout`  | Yes       | Mitigation timeout after the limit is hit |

Set these workspace-specific Terraform variables on `account-access`.

| Category  | Key                           | Sensitive | HCL |
| --------- | ----------------------------- | --------- | --- |
| Terraform | `cloudflare_access_team_name` | No        | Yes |
| Terraform | `argocd_admin_emails`         | No        | Yes |
| Terraform | `argocd_readonly_emails`      | No        | Yes |
| Terraform | `stg_allowed_emails`          | No        | Yes |

Set this workspace-specific Terraform variable on `zone-litomi-in-dns`:

| Category  | Key             | Sensitive | Notes                                          |
| --------- | --------------- | --------- | ---------------------------------------------- |
| Terraform | `oke_edge_ipv4` | Yes       | Reserved OCI public IPv4 for the prod OKE edge |

The DNS workspace does not read OCI state directly. After the OCI prod
workspace creates or replaces the reserved edge IP, copy that output into the
`zone-litomi-in-dns` workspace variable in HCP Terraform.

## Cross-Workspace Dependency

`zone/litomi.in/dns` reads `selfhost_tunnel_cname` from
`account-selfhost-tunnel` via `terraform_remote_state`.
Allow the DNS workspace to read the tunnel workspace state outputs in HCP
Terraform before planning DNS. Prefer granting this to the DNS workspace only,
not global remote-state access.

## Operating Rules

- Do not run Cloudflare changes from local `.tfvars` or `.env` files.
- Do not use local `terraform.tfstate` as an authority.
- Do not edit Cloudflare resources in the dashboard during normal operations.
- If a dashboard change is required for break-glass recovery, import or update
  Terraform before the next normal apply.
- Prefer adding a new product or phase as a new workspace instead of expanding a
  broad shared state.
