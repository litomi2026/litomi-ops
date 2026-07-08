provider "oci" {
  region               = var.oci_region
  tenancy_ocid         = var.oci_tenancy_ocid
  user_ocid            = var.oci_user_ocid
  fingerprint          = var.oci_fingerprint
  private_key          = var.oci_private_key
  private_key_password = var.oci_private_key_password
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
