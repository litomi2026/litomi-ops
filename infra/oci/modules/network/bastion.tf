resource "oci_bastion_bastion" "oke_api" {
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_id
  client_cidr_block_allow_list = var.bastion_client_allowed_cidrs_ipv4
  max_session_ttl_in_seconds   = 10800
  name                         = "${var.resource_name_prefix}-oke-api-bastion"
  target_subnet_id             = oci_core_subnet.bastion.id
  freeform_tags                = var.freeform_tags
}
