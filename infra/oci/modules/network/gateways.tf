resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-igw"
  vcn_id         = oci_core_vcn.this.id
  enabled        = true
  freeform_tags  = var.freeform_tags
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-nat"
  public_ip_id   = oci_core_public_ip.nat_gateway.id
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags
}

resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-sgw"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags

  services {
    service_id = local.oracle_services_network_service.id
  }
}
