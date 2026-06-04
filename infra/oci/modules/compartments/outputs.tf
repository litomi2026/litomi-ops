output "namespace_compartment_id" {
  description = "Parent namespace compartment OCID."
  value       = oci_identity_compartment.namespace.id
}

output "workload_compartment_id" {
  description = "Child environment compartment OCID."
  value       = oci_identity_compartment.workload.id
}

output "namespace_name" {
  description = "Parent namespace compartment name."
  value       = oci_identity_compartment.namespace.name
}

output "workload_name" {
  description = "Child environment compartment name."
  value       = oci_identity_compartment.workload.name
}
