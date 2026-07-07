# The stack URL and admin service account token are produced by the grafana-cloud
# workspace. Grant this workspace remote-state read on grafana-cloud only.
data "terraform_remote_state" "grafana_cloud" {
  backend = "remote"

  config = {
    organization = "litomi"
    workspaces = {
      name = "grafana-cloud"
    }
  }
}

provider "grafana" {
  url  = data.terraform_remote_state.grafana_cloud.outputs.stack_url
  auth = data.terraform_remote_state.grafana_cloud.outputs.stack_service_account_token
}
