terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

resource "oci_identity_tag_namespace" "this" {
  compartment_id = var.compartment_id
  description    = var.namespace_description
  name           = var.namespace_name
  freeform_tags  = var.freeform_tags
}

resource "oci_identity_tag" "worker_principal" {
  tag_namespace_id = oci_identity_tag_namespace.this.id
  description      = var.worker_tag_key_description
  name             = var.worker_tag_key_name
}
