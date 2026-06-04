resource "oci_core_subnet" "public_lb" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.resource_name_prefix}-public-lb"
  dns_label                  = "lbpub"
  cidr_block                 = var.public_lb_subnet_cidr_block
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public_lb.id]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  freeform_tags              = var.freeform_tags
}

resource "oci_core_subnet" "worker" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.resource_name_prefix}-private-workers"
  dns_label                  = "workers"
  cidr_block                 = var.worker_subnet_cidr_block
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.worker.id]
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  freeform_tags              = var.freeform_tags
}

resource "oci_core_subnet" "api_endpoint" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.resource_name_prefix}-api-endpoint"
  dns_label                  = "apiep"
  cidr_block                 = var.api_endpoint_subnet_cidr_block
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.api.id]
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  freeform_tags              = var.freeform_tags
}

resource "oci_core_subnet" "bastion" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.resource_name_prefix}-bastion"
  dns_label                  = "bastion"
  cidr_block                 = var.bastion_subnet_cidr_block
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.bastion.id]
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  freeform_tags              = var.freeform_tags
}

resource "oci_core_subnet" "pod" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.resource_name_prefix}-pods"
  dns_label                  = "pods"
  cidr_block                 = var.pod_subnet_cidr_block
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.pod.id]
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  freeform_tags              = var.freeform_tags
}
