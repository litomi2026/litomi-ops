output "cluster_id" {
  description = "OKE cluster OCID."
  value       = oci_containerengine_cluster.this.id
}

output "cluster_private_endpoint" {
  description = "Private Kubernetes API endpoint."
  value       = one(oci_containerengine_cluster.this.endpoints).private_endpoint
}

output "backend_nsg_id" {
  description = "Backend NSG OCID referenced by the edge Gateway service annotation."
  value       = oci_core_network_security_group.backend.id
}

output "node_pool_ids" {
  description = "Map of node pool IDs keyed by node pool name."
  value       = { for name, node_pool in oci_containerengine_node_pool.this : name => node_pool.id }
}
