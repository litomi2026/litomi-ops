output "edge_reserved_public_ip" {
  description = "Reserved IPv4 intended for the public edge NLB and Cloudflare DNS HCP variable."
  value       = module.network.edge_reserved_public_ip
}

output "nat_gateway_reserved_public_ip" {
  description = "Reserved IPv4 intended for NAT gateway egress allowlists."
  value       = module.network.nat_gateway_reserved_public_ip
}

output "vault_ocid" {
  description = "Vault OCID consumed by External Secrets."
  value       = module.vault.vault_id
}

output "web_secret_name" {
  description = "Vault secret name for the web workload."
  value       = module.vault.web_secret_name
}

output "api_secret_name" {
  description = "Vault secret name for the API workload."
  value       = module.vault.api_secret_name
}

output "argocd_secret_name" {
  description = "Vault secret name for Argo CD."
  value       = module.vault.argocd_secret_name
}

output "cert_manager_secret_name" {
  description = "Vault secret name for cert-manager."
  value       = module.vault.cert_manager_secret_name
}

output "web_secret_id" {
  description = "Vault secret OCID for the web workload."
  value       = module.vault.web_secret_id
}

output "api_secret_id" {
  description = "Vault secret OCID for the API workload."
  value       = module.vault.api_secret_id
}

output "argocd_secret_id" {
  description = "Vault secret OCID for Argo CD."
  value       = module.vault.argocd_secret_id
}

output "cert_manager_secret_id" {
  description = "Vault secret OCID for cert-manager."
  value       = module.vault.cert_manager_secret_id
}

output "namespace_compartment_id" {
  description = "Parent namespace compartment OCID."
  value       = module.compartments.namespace_compartment_id
}

output "workload_compartment_id" {
  description = "Child workload compartment OCID."
  value       = module.compartments.workload_compartment_id
}

output "cluster_id" {
  description = "OKE cluster OCID."
  value       = module.oke.cluster_id
}

output "cluster_private_endpoint" {
  description = "Private Kubernetes API endpoint."
  value       = module.oke.cluster_private_endpoint
}

output "edge_reserved_public_ip_ocid" {
  description = "Reserved public IP OCID for the edge Gateway service."
  value       = module.network.edge_reserved_public_ip_ocid
}

output "nat_gateway_reserved_public_ip_ocid" {
  description = "Reserved public IP OCID intended for NAT gateway egress."
  value       = module.network.nat_gateway_reserved_public_ip_ocid
}

output "nat_gateway_public_ip" {
  description = "Currently active NAT gateway public IPv4 address."
  value       = module.network.nat_gateway_public_ip
}

output "api_endpoint_nsg_ocid" {
  description = "API endpoint NSG OCID."
  value       = module.network.api_endpoint_nsg_id
}

output "worker_nsg_ocid" {
  description = "Worker NSG OCID."
  value       = module.network.worker_nsg_id
}

output "pod_nsg_ocid" {
  description = "Pod NSG OCID."
  value       = module.network.pod_nsg_id
}

output "bastion_ocid" {
  description = "OCI Bastion OCID for private Kubernetes API access."
  value       = module.network.bastion_id
}

output "bastion_private_endpoint_ip" {
  description = "Private endpoint IPv4 address used by OCI Bastion inside the VCN."
  value       = module.network.bastion_private_endpoint_ip
}
