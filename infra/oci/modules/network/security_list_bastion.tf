resource "oci_core_security_list" "bastion" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-bastion-seclist"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.freeform_tags

  egress_security_rules {
    description      = "Bastion private endpoint to Kubernetes API."
    destination      = var.api_endpoint_subnet_cidr_block
    destination_type = "CIDR_BLOCK"
    protocol         = "6"

    tcp_options {
      max = 6443
      min = 6443
    }
  }

  egress_security_rules {
    description      = "Bastion private endpoint to OCI services."
    destination      = local.oracle_services_network_service.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"

    tcp_options {
      max = 443
      min = 443
    }
  }

  egress_security_rules {
    description      = "Bastion private endpoint path discovery to Kubernetes API."
    destination      = var.api_endpoint_subnet_cidr_block
    destination_type = "CIDR_BLOCK"
    protocol         = "1"

    icmp_options {
      code = 4
      type = 3
    }
  }
}
