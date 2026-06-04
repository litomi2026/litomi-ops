resource "oci_core_network_security_group_security_rule" "api_egress_oke_service_443" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "EGRESS"
  description               = "API endpoint to OKE service."
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

resource "oci_core_network_security_group_security_rule" "api_egress_worker_kubelet_10250" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "EGRESS"
  description               = "API endpoint to worker kubelet."
  destination               = oci_core_network_security_group.worker.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 10250
      min = 10250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_egress_worker_path_discovery" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "EGRESS"
  description               = "Path discovery from API endpoint to workers."
  destination               = oci_core_network_security_group.worker.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "1"

  icmp_options {
    code = 4
    type = 3
  }
}

resource "oci_core_network_security_group_security_rule" "api_egress_pod_all" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "EGRESS"
  description               = "OKE-required VCN-native control-plane-to-pod traffic."
  destination               = oci_core_network_security_group.pod.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}

resource "oci_core_network_security_group_security_rule" "api_ingress_bastion_6443" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "INGRESS"
  description               = "Bastion sessions to Kubernetes API."
  source                    = "${oci_bastion_bastion.oke_api.private_endpoint_ip_address}/32"
  source_type               = "CIDR_BLOCK"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_ingress_worker_6443" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "INGRESS"
  description               = "Workers to Kubernetes API."
  source                    = oci_core_network_security_group.worker.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_ingress_worker_12250" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "INGRESS"
  description               = "Workers to control plane."
  source                    = oci_core_network_security_group.worker.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 12250
      min = 12250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_ingress_pod_6443" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "INGRESS"
  description               = "Pods to Kubernetes API."
  source                    = oci_core_network_security_group.pod.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_ingress_pod_12250" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "INGRESS"
  description               = "Pods to control plane."
  source                    = oci_core_network_security_group.pod.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = 12250
      min = 12250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_ingress_worker_path_discovery" {
  network_security_group_id = oci_core_network_security_group.api_endpoint.id
  direction                 = "INGRESS"
  description               = "Path discovery from workers."
  source                    = oci_core_network_security_group.worker.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "1"

  icmp_options {
    code = 4
    type = 3
  }
}
