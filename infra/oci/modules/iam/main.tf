terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

resource "oci_identity_dynamic_group" "oke_workers" {
  compartment_id = var.tenancy_ocid
  description    = "OKE worker nodes for ${var.resource_name_prefix} that need OCI Vault read access"
  matching_rule = format(
    "all {instance.compartment.id = '%s', tag.%s.%s.value = '%s'}",
    var.workload_compartment_id,
    var.worker_tag_namespace_name,
    var.worker_tag_key_name,
    var.worker_tag_value,
  )
  name = "${var.resource_name_prefix}-oke-workers-dg"
}

resource "oci_identity_policy" "oke_workers_vault" {
  compartment_id = var.policy_compartment_id
  description    = "Allow ${var.resource_name_prefix} OKE worker nodes to read OCI Vault secrets"
  name           = "${var.resource_name_prefix}-oke-workers-vault-policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_workers.name} to read vaults in compartment id ${var.workload_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_workers.name} to read secret-family in compartment id ${var.workload_compartment_id}",
  ]
}

resource "oci_identity_policy" "oke_cluster_lb" {
  compartment_id = var.policy_compartment_id
  description    = "Allow the ${var.resource_name_prefix} OKE cluster principal to create NLBs, manage NSG-backed security rules, and use the reserved public IP"
  name           = "${var.resource_name_prefix}-oke-cluster-lb-policy"
  statements = [
    "Allow any-user to manage network-load-balancers in compartment id ${var.workload_compartment_id} where all { request.principal.type = 'cluster', request.principal.id = '${var.cluster_id}' }",
    "Allow any-user to manage network-security-groups in compartment id ${var.workload_compartment_id} where all { request.principal.type = 'cluster', request.principal.id = '${var.cluster_id}' }",
    "Allow any-user to manage vcns in compartment id ${var.workload_compartment_id} where all { request.principal.type = 'cluster', request.principal.id = '${var.cluster_id}' }",
    "Allow any-user to use private-ips in compartment id ${var.workload_compartment_id} where all { request.principal.type = 'cluster', request.principal.id = '${var.cluster_id}' }",
    "Allow any-user to manage public-ips in compartment id ${var.workload_compartment_id} where all { request.principal.type = 'cluster', request.principal.id = '${var.cluster_id}' }",
  ]
}

resource "oci_identity_policy" "oke_cluster_tag_namespace" {
  compartment_id = var.policy_compartment_id
  description    = "Allow the ${var.resource_name_prefix} OKE cluster principal to apply the shared worker identity defined tag"
  name           = "${var.resource_name_prefix}-oke-cluster-tag-policy"
  statements = [
    "Allow any-user to use tag-namespaces in compartment id ${var.tag_namespace_compartment_id} where all { request.principal.type = 'cluster', request.principal.id = '${var.cluster_id}' }",
  ]
}
