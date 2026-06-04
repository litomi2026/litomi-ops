# OCI Terraform

`infra/oci` manages Litomi OKE infrastructure through HCP Terraform
Version Control Workflow.

Principles:

- OCI API credentials, private keys, secret values, ACME account details, and
  runtime bootstrap identifiers stay outside Git.
- OCI public IPs, Vault OCIDs, NSG OCIDs, and similar operational identifiers
  are not committed even when they are not secrets.
- Terraform owns OCI topology, reserved public IPs, Vault/KMS containers, and
  IAM policy. Kubernetes manifests consume runtime identifiers through
  bootstrap resources created outside Git.
- OKE uses `BASIC_CLUSTER`; Enhanced-only features such as Workload Identity
  are intentionally not assumed.
- OCI Vault secret containers are created by Terraform, but actual secret
  versions are rotated out of band so Terraform state never becomes the source
  of sensitive runtime values.

Production is managed by `environment/prod`. Future `stg` and `dev`
environments should be added as separate HCP Terraform workspaces and separate
OKE clusters, not as overlays sharing the production cluster.
