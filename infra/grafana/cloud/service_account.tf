# Admin service account whose token authenticates the grafana-stack-prod
# workspace's in-stack provider (alerting, folders, dashboards, SLOs).
resource "grafana_cloud_stack_service_account" "terraform" {
  stack_slug  = grafana_cloud_stack.this.slug
  name        = "terraform-stack"
  role        = "Admin"
  is_disabled = false
}

resource "grafana_cloud_stack_service_account_token" "terraform" {
  stack_slug         = grafana_cloud_stack.this.slug
  name               = "terraform-stack"
  service_account_id = grafana_cloud_stack_service_account.terraform.id
}
