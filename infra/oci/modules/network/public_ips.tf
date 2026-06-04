resource "oci_core_public_ip" "edge" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-edge-nlb-ip"
  lifetime       = "RESERVED"
  freeform_tags  = var.freeform_tags

  lifecycle {
    # OCI CCM이 reserved public IP를 NLB private IP에 연결하면서 private_ip_id를 갱신한다.
    # 이 연결 상태는 Gateway Service runtime이 소유하므로 Terraform drift로 보지 않는다.
    ignore_changes = [private_ip_id]
  }
}

resource "oci_core_public_ip" "nat_gateway" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_name_prefix}-nat-egress-ip"
  lifetime       = "RESERVED"
  freeform_tags  = var.freeform_tags
}
