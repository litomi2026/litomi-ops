provider "oci" {
  region               = var.region
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key          = var.private_key
  private_key_password = var.private_key_password
}

# The collector credential is minted by the grafana-cloud workspace. This
# workspace never holds Grafana credentials — it only reads the token output.
data "terraform_remote_state" "grafana_cloud" {
  backend = "remote"

  config = {
    organization = "litomi"
    workspaces = {
      name = "grafana-cloud"
    }
  }
}
