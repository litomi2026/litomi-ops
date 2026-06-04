output "namespace_compartment_id" {
  description = "Compartment OCID that owns the defined tag namespace."
  value       = var.compartment_id
}

output "namespace_name" {
  description = "Defined tag namespace name."
  value       = oci_identity_tag_namespace.this.name
}

output "worker_tag_key_name" {
  description = "Defined tag key name used for OKE worker nodes."
  value       = oci_identity_tag.worker_principal.name
}

output "worker_tag_fq_name" {
  description = "Fully-qualified defined tag key for OKE worker nodes."
  value       = "${oci_identity_tag_namespace.this.name}.${oci_identity_tag.worker_principal.name}"
}
