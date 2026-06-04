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
    if service.name == "All ICN Services In Oracle Services Network"
  ])
}
