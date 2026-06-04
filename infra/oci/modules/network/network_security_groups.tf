resource "oci_core_network_security_group" "api_endpoint" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-api-endpoint-nsg"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags
}

resource "oci_core_network_security_group" "worker" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-worker-nsg"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags
}

resource "oci_core_network_security_group" "pod" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-pod-nsg"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags
}
