locals {
  resource_name_prefix = "${var.service_name}-${var.environment_name}"
  private_key_value = var.private_key != null ? var.private_key : (
    var.private_key_path != null ? trimspace(file(pathexpand(var.private_key_path))) : null
  )
  web_secret_name          = "${local.resource_name_prefix}-web"
  api_secret_name          = "${local.resource_name_prefix}-api"
  cataloger_secret_name    = "${local.resource_name_prefix}-cataloger"
  notifier_secret_name     = "${local.resource_name_prefix}-notifier"
  chat_secret_name         = "${local.resource_name_prefix}-chat"
  chat_worker_secret_name  = "${local.resource_name_prefix}-chat-worker"
  chat_push_secret_name    = "${local.resource_name_prefix}-chat-push"
  argocd_secret_name       = "${local.resource_name_prefix}-argocd"
  cert_manager_secret_name = "${local.resource_name_prefix}-cert-manager"
  worker_tag_value         = coalesce(var.worker_tag_value, "${local.resource_name_prefix}-oke-worker")
  freeform_tags = {
    environment = var.environment_name
    managed-by  = "terraform"
    service     = var.service_name
  }
}

provider "oci" {
  region               = var.region
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key          = local.private_key_value
  private_key_password = var.private_key_password
}

provider "oci" {
  alias                = "home"
  region               = var.home_region
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key          = local.private_key_value
  private_key_password = var.private_key_password
}

module "compartments" {
  source = "../../modules/compartments"
  providers = {
    oci = oci.home
  }

  tenancy_ocid          = var.tenancy_ocid
  namespace_name        = var.namespace_compartment_name
  namespace_description = var.namespace_compartment_description
  workload_name         = var.workload_compartment_name
  workload_description  = var.workload_compartment_description
  freeform_tags         = local.freeform_tags
}

module "network" {
  source = "../../modules/network"

  compartment_id                    = module.compartments.workload_compartment_id
  resource_name_prefix              = local.resource_name_prefix
  vcn_cidr_blocks                   = var.vcn_cidr_blocks
  vcn_dns_label                     = var.vcn_dns_label
  public_lb_subnet_cidr_block       = var.public_lb_subnet_cidr_block
  worker_subnet_cidr_block          = var.worker_subnet_cidr_block
  api_endpoint_subnet_cidr_block    = var.api_endpoint_subnet_cidr_block
  bastion_subnet_cidr_block         = var.bastion_subnet_cidr_block
  pod_subnet_cidr_block             = var.pod_subnet_cidr_block
  bastion_client_allowed_cidrs_ipv4 = var.bastion_client_allowed_cidrs_ipv4
  worker_external_https_cidrs_ipv4  = var.worker_external_https_cidrs_ipv4
  pod_external_https_cidrs_ipv4     = var.pod_external_https_cidrs_ipv4
  pod_postgresql_cidrs_ipv4         = var.pod_postgresql_cidrs_ipv4
  pod_postgresql_ports              = var.pod_postgresql_ports
  pod_redis_cidrs_ipv4              = var.pod_redis_cidrs_ipv4
  pod_redis_ports                   = var.pod_redis_ports
  pod_kafka_cidrs_ipv4              = var.pod_kafka_cidrs_ipv4
  pod_kafka_ports                   = var.pod_kafka_ports
  freeform_tags                     = local.freeform_tags
}

module "tags" {
  source = "../../modules/tags"
  providers = {
    oci = oci.home
  }

  compartment_id             = module.compartments.namespace_compartment_id
  namespace_name             = var.worker_tag_namespace_name
  namespace_description      = var.worker_tag_namespace_description
  worker_tag_key_name        = var.worker_tag_key_name
  worker_tag_key_description = var.worker_tag_key_description
  freeform_tags              = local.freeform_tags
}

module "vault" {
  source = "../../modules/vault"

  compartment_id           = module.compartments.workload_compartment_id
  resource_name_prefix     = local.resource_name_prefix
  web_secret_name          = local.web_secret_name
  api_secret_name          = local.api_secret_name
  cataloger_secret_name    = local.cataloger_secret_name
  notifier_secret_name     = local.notifier_secret_name
  chat_secret_name         = local.chat_secret_name
  chat_worker_secret_name  = local.chat_worker_secret_name
  chat_push_secret_name    = local.chat_push_secret_name
  argocd_secret_name       = local.argocd_secret_name
  cert_manager_secret_name = local.cert_manager_secret_name
  freeform_tags            = local.freeform_tags
}

module "oke" {
  source = "../../modules/oke"

  compartment_id               = module.compartments.workload_compartment_id
  resource_name_prefix         = local.resource_name_prefix
  kubernetes_version           = var.kubernetes_version
  vcn_id                       = module.network.vcn_id
  api_endpoint_subnet_id       = module.network.api_endpoint_subnet_id
  api_endpoint_nsg_ids         = [module.network.api_endpoint_nsg_id]
  service_lb_subnet_ids        = [module.network.public_lb_subnet_id]
  worker_subnet_id             = module.network.worker_subnet_id
  worker_nsg_ids               = [module.network.worker_nsg_id]
  pod_subnet_id                = module.network.pod_subnet_id
  pod_nsg_ids                  = [module.network.pod_nsg_id]
  availability_domain          = var.availability_domain
  node_image_id                = var.node_image_id
  node_boot_volume_size_in_gbs = var.node_boot_volume_size_in_gbs
  ssh_public_key               = var.ssh_public_key
  node_pools                   = var.node_pools
  worker_tag_namespace_name    = module.tags.namespace_name
  worker_tag_key_name          = module.tags.worker_tag_key_name
  worker_tag_value             = local.worker_tag_value
  kubernetes_pods_cidr         = var.kubernetes_pods_cidr
  kubernetes_services_cidr     = var.kubernetes_services_cidr
  freeform_tags                = local.freeform_tags
}

module "iam" {
  source = "../../modules/iam"
  providers = {
    oci = oci.home
  }

  tenancy_ocid                 = var.tenancy_ocid
  policy_compartment_id        = module.compartments.namespace_compartment_id
  workload_compartment_id      = module.compartments.workload_compartment_id
  tag_namespace_compartment_id = module.tags.namespace_compartment_id
  resource_name_prefix         = local.resource_name_prefix
  cluster_id                   = module.oke.cluster_id
  worker_tag_namespace_name    = module.tags.namespace_name
  worker_tag_key_name          = module.tags.worker_tag_key_name
  worker_tag_value             = local.worker_tag_value
}
