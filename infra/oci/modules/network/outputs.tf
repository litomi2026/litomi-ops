output "vcn_id" {
  description = "VCN OCID."
  value       = oci_core_vcn.this.id
}

output "public_lb_subnet_id" {
  description = "Public LB subnet OCID."
  value       = oci_core_subnet.public_lb.id
}

output "worker_subnet_id" {
  description = "Worker subnet OCID."
  value       = oci_core_subnet.worker.id
}

output "api_endpoint_subnet_id" {
  description = "API endpoint subnet OCID."
  value       = oci_core_subnet.api_endpoint.id
}

output "bastion_subnet_id" {
  description = "Bastion private endpoint subnet OCID."
  value       = oci_core_subnet.bastion.id
}

output "pod_subnet_id" {
  description = "Pod subnet OCID."
  value       = oci_core_subnet.pod.id
}

output "edge_reserved_public_ip" {
  description = "Reserved IPv4 address used by the edge Gateway service annotation."
  value       = oci_core_public_ip.edge.ip_address
}

output "edge_reserved_public_ip_ocid" {
  description = "Reserved public IP OCID for the edge Gateway service."
  value       = oci_core_public_ip.edge.id
}

output "nat_gateway_reserved_public_ip" {
  description = "Reserved IPv4 address intended for NAT gateway egress allowlists."
  value       = oci_core_public_ip.nat_gateway.ip_address
}

output "nat_gateway_reserved_public_ip_ocid" {
  description = "Reserved public IP OCID intended for NAT gateway egress."
  value       = oci_core_public_ip.nat_gateway.id
}

output "nat_gateway_public_ip" {
  description = "Currently active NAT gateway public IPv4 address."
  value       = oci_core_nat_gateway.this.nat_ip
}

output "api_endpoint_nsg_id" {
  description = "API endpoint NSG OCID."
  value       = oci_core_network_security_group.api_endpoint.id
}

output "worker_nsg_id" {
  description = "Worker NSG OCID."
  value       = oci_core_network_security_group.worker.id
}

output "pod_nsg_id" {
  description = "Pod NSG OCID."
  value       = oci_core_network_security_group.pod.id
}

output "bastion_id" {
  description = "OCI Bastion OCID for private Kubernetes API access."
  value       = oci_bastion_bastion.oke_api.id
}

output "bastion_private_endpoint_ip" {
  description = "Private endpoint IPv4 address used by OCI Bastion inside the VCN."
  value       = oci_bastion_bastion.oke_api.private_endpoint_ip_address
}
