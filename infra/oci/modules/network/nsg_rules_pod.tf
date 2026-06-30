resource "oci_core_network_security_group_security_rule" "pod_egress_pod_all" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "OKE-required VCN-native pod-to-pod traffic."
  destination               = oci_core_network_security_group.pod.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}

resource "oci_core_network_security_group_security_rule" "pod_egress_oci_services_443" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Pods to OCI services."
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

resource "oci_core_network_security_group_security_rule" "pod_egress_internet_https" {
  for_each = toset(var.pod_external_https_cidrs_ipv4)

  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Pods to explicit external HTTPS allowlist via NAT."
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

resource "oci_core_network_security_group_security_rule" "pod_egress_postgresql" {
  for_each = local.pod_postgresql_egress_rules

  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Pods to explicit PostgreSQL TCP ${each.value.port} allowlist via NAT."
  destination               = each.value.cidr
  destination_type          = "CIDR_BLOCK"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = each.value.port
      min = each.value.port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "pod_egress_redis" {
  for_each = local.pod_redis_egress_rules

  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Pods to explicit Redis TCP ${each.value.port} allowlist via NAT."
  destination               = each.value.cidr
  destination_type          = "CIDR_BLOCK"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = each.value.port
      min = each.value.port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "pod_egress_kafka" {
  for_each = local.pod_kafka_egress_rules

  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Pods to explicit Kafka TCP ${each.value.port} allowlist via NAT."
  destination               = each.value.cidr
  destination_type          = "CIDR_BLOCK"
  protocol                  = "6"

  tcp_options {
    destination_port_range {
      max = each.value.port
      min = each.value.port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "pod_egress_path_discovery" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Path discovery from pods."
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  protocol                  = "1"

  icmp_options {
    code = 4
    type = 3
  }
}

resource "oci_core_network_security_group_security_rule" "pod_egress_api_6443" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Pods to Kubernetes API."
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

resource "oci_core_network_security_group_security_rule" "pod_egress_api_12250" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Pods to control plane."
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

resource "oci_core_network_security_group_security_rule" "pod_egress_worker_kubelet_10250" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "EGRESS"
  description               = "Pods to worker kubelets for resource metrics."
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

resource "oci_core_network_security_group_security_rule" "pod_ingress_api_all" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "INGRESS"
  description               = "OKE-required VCN-native control-plane-to-pod traffic."
  source                    = oci_core_network_security_group.api_endpoint.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}

resource "oci_core_network_security_group_security_rule" "pod_ingress_worker_all" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "INGRESS"
  description               = "OKE-required VCN-native worker-to-pod traffic."
  source                    = oci_core_network_security_group.worker.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}

resource "oci_core_network_security_group_security_rule" "pod_ingress_pod_all" {
  network_security_group_id = oci_core_network_security_group.pod.id
  direction                 = "INGRESS"
  description               = "OKE-required VCN-native pod-to-pod traffic."
  source                    = oci_core_network_security_group.pod.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
}
