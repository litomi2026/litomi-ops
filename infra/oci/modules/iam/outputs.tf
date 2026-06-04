output "dynamic_group_name" {
  description = "Dynamic group name used by worker node instance principals."
  value       = oci_identity_dynamic_group.oke_workers.name
}
