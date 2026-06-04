resource "oci_core_network_security_group_security_rule" "worker_egress_worker_all" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "EGRESS"
  description               = "OKE-required VCN-native worker-to-worker traffic."
  destination               = oci_core_network_security_group.worker.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}

resource "oci_core_network_security_group_security_rule" "worker_egress_pod_all" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "EGRESS"
  description               = "OKE-required VCN-native worker-to-pod traffic."
  destination               = oci_core_network_security_group.pod.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}

resource "oci_core_network_security_group_security_rule" "worker_egress_path_discovery" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "EGRESS"
  description               = "Path discovery from workers."
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  protocol                  = "1"

  icmp_options {
    code = 4
    type = 3
  }
}

resource "oci_core_network_security_group_security_rule" "worker_egress_internet_https" {
  for_each = toset(var.worker_external_https_cidrs_ipv4)

  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "EGRESS"
  description               = "Workers to explicit external HTTPS allowlist via NAT."
  destination               = each.value
  destination_type          = "CIDR_BLOCK"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "worker_egress_oci_services_443" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "EGRESS"
  description               = "Workers to OCI services."
  destination               = local.oracle_services_network_service.cidr_block
  destination_type          = "SERVICE_CIDR_BLOCK"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "worker_egress_api_6443" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "EGRESS"
  description               = "Workers to Kubernetes API."
  destination               = oci_core_network_security_group.api_endpoint.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "worker_egress_api_12250" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "EGRESS"
  description               = "Workers to control plane."
  destination               = oci_core_network_security_group.api_endpoint.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 12250
      min = 12250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "worker_ingress_worker_all" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "INGRESS"
  description               = "OKE-required VCN-native worker-to-worker traffic."
  source                    = oci_core_network_security_group.worker.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}

resource "oci_core_network_security_group_security_rule" "worker_ingress_pod_all" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "INGRESS"
  description               = "OKE-required VCN-native pod-to-worker traffic."
  source                    = oci_core_network_security_group.pod.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}

resource "oci_core_network_security_group_security_rule" "worker_ingress_api_tcp" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "INGRESS"
  description               = "Control plane TCP to workers."
  source                    = oci_core_network_security_group.api_endpoint.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "6"
}

resource "oci_core_network_security_group_security_rule" "worker_ingress_api_path_discovery" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "INGRESS"
  description               = "Control plane path discovery to workers."
  source                    = oci_core_network_security_group.api_endpoint.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "1"

  icmp_options {
    code = 4
    type = 3
  }
}

resource "oci_core_network_security_group_security_rule" "worker_ingress_path_discovery" {
  network_security_group_id = oci_core_network_security_group.worker.id
  direction                 = "INGRESS"
  description               = "Path discovery to workers."
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  protocol                  = "1"

  icmp_options {
    code = 4
    type = 3
  }
}
