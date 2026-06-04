terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

resource "oci_identity_compartment" "namespace" {
  compartment_id = var.tenancy_ocid
  name           = var.namespace_name
  description    = var.namespace_description
  freeform_tags  = var.freeform_tags
}

resource "oci_identity_compartment" "workload" {
  compartment_id = oci_identity_compartment.namespace.id
  name           = var.workload_name
  description    = var.workload_description
  freeform_tags  = var.freeform_tags
}
