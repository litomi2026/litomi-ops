terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

locals {
  node_pool_names = {
    for role, pool in var.node_pools : role => "${var.resource_name_prefix}-nodepool-${role}"
  }

  service_lb_tags = merge(var.freeform_tags, {
    component = "edge"
  })

  worker_defined_tags = {
    "${var.worker_tag_namespace_name}.${var.worker_tag_key_name}" = var.worker_tag_value
  }

  # OKE 기본 이미지는 부팅 시 루트 파일시스템을 부트볼륨(100GB)까지 자동 확장하지 않아
  # 게스트 루트가 이미지 기본값(~35GB)에 머문다 → 커스텀 user_data를 주면 OKE 부트스트랩이 
  # 자동 주입되지 않으므로 oke_init_script를 직접 받아 실행해야 한다.
  node_cloud_init = <<-EOT
    #!/usr/bin/env bash
    set -uo pipefail
    for i in $(seq 1 10); do
      curl --fail --silent --show-error \
        --retry 5 --retry-delay 3 --retry-connrefused \
        -H "Authorization: Bearer Oracle" -L0 \
        http://169.254.169.254/opc/v2/instance/metadata/oke_init_script \
        -o /var/run/oke-init.sh && break
      sleep 5
    done
    bash /var/run/oke-init.sh
    /usr/libexec/oci-growfs -y || logger -t oke-growfs "oci-growfs failed"
  EOT
}

resource "oci_core_network_security_group" "backend" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.resource_name_prefix}-oke-backend-nsg"
  freeform_tags  = var.freeform_tags

  lifecycle {
    # OCI CCM/runtime이 service LB backend NSG에 provider ownership tag를 덧붙일 수 있다.
    # Terraform이 소유하지 않는 태그 때문에 NSG를 교체하지 않도록 이 태그만 좁게 무시한다.
    ignore_changes = [freeform_tags["ManagedBy"]]
  }
}

resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "${var.resource_name_prefix}-oke"
  type               = "BASIC_CLUSTER"
  vcn_id             = var.vcn_id
  freeform_tags      = var.freeform_tags

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  endpoint_config {
    is_public_ip_enabled = false
    nsg_ids              = var.api_endpoint_nsg_ids
    subnet_id            = var.api_endpoint_subnet_id
  }

  options {
    ip_families = ["IPv4"]

    kubernetes_network_config {
      pods_cidr     = var.kubernetes_pods_cidr
      services_cidr = var.kubernetes_services_cidr
    }

    persistent_volume_config {
      freeform_tags = var.freeform_tags
    }

    service_lb_config {
      backend_nsg_ids = [oci_core_network_security_group.backend.id]
      freeform_tags   = local.service_lb_tags
    }

    service_lb_subnet_ids = var.service_lb_subnet_ids
  }
}

resource "oci_containerengine_node_pool" "this" {
  for_each = var.node_pools

  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = local.node_pool_names[each.key]
  node_shape         = each.value.shape
  ssh_public_key     = var.ssh_public_key
  freeform_tags      = var.freeform_tags

  # 루트 파일시스템을 부트볼륨 전체로 확장(oci-growfs). OKE 부트스트랩 포함.
  node_metadata = {
    user_data = base64encode(local.node_cloud_init)
  }

  lifecycle {
    precondition {
      condition     = length(local.node_pool_names[each.key]) <= 32
      error_message = "OKE node pool names must be 32 characters or less."
    }
  }

  initial_node_labels {
    key   = "node-pool-role"
    value = each.value.node_label
  }

  node_shape_config {
    memory_in_gbs = each.value.memory_in_gbs
    ocpus         = each.value.ocpus
  }

  node_source_details {
    boot_volume_size_in_gbs = var.node_boot_volume_size_in_gbs
    image_id                = var.node_image_id
    source_type             = "IMAGE"
  }

  node_config_details {
    defined_tags                        = each.value.vault_access ? local.worker_defined_tags : {}
    freeform_tags                       = var.freeform_tags
    is_pv_encryption_in_transit_enabled = true
    nsg_ids                             = concat([oci_core_network_security_group.backend.id], var.worker_nsg_ids)
    size                                = each.value.size

    node_pool_pod_network_option_details {
      cni_type          = "OCI_VCN_IP_NATIVE"
      max_pods_per_node = var.max_pods_per_node
      pod_nsg_ids       = var.pod_nsg_ids
      pod_subnet_ids    = [var.pod_subnet_id]
    }

    placement_configs {
      availability_domain = var.availability_domain
      fault_domains       = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"]
      subnet_id           = var.worker_subnet_id
    }
  }
}
