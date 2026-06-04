resource "oci_core_security_list" "public_lb" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-public-lb-seclist"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags
}
