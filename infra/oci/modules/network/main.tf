terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

data "oci_core_services" "oracle_services_network" {}

locals {
  oracle_services_network_service = one([
    for service in data.oci_core_services.oracle_services_network.services : service
    if startswith(service.name, "All ") && endswith(service.name, " Services In Oracle Services Network")
  ])

  pod_redis_egress_rules = {
    for pair in setproduct(var.pod_redis_cidrs_ipv4, var.pod_redis_ports) :
    "${pair[0]}:${pair[1]}" => {
      cidr = pair[0]
      port = pair[1]
    }
  }
}
