resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-public-rt"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags

  route_rules {
    description       = "Public internet egress"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-private-rt"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags

  route_rules {
    description       = "Private internet egress via NAT"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }

  route_rules {
    description       = "Oracle services access"
    destination       = local.oracle_services_network_service.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }
}
