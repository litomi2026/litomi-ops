variable "region" {
  description = "OCI region."
  type        = string
}

variable "home_region" {
  description = "OCI tenancy home region used for Identity service CRUD operations."
  type        = string
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID used by Terraform."
  type        = string
}

variable "fingerprint" {
  description = "OCI API key fingerprint."
  type        = string
}

variable "private_key" {
  description = "OCI API private key content for HCP Terraform."
  type        = string
  default     = null
  sensitive   = true
  nullable    = true
}

variable "private_key_path" {
  description = "OCI API private key path for local runs."
  type        = string
  default     = null
  nullable    = true
}

variable "private_key_password" {
  description = "Optional OCI API private key password."
  type        = string
  default     = null
  sensitive   = true
  nullable    = true
}

variable "service_name" {
  description = "Logical service namespace."
  type        = string
  default     = "litomi"
}

variable "environment_name" {
  description = "Logical environment name."
  type        = string
  default     = "prod"
}

variable "namespace_compartment_name" {
  description = "Parent namespace compartment name."
  type        = string
  default     = "litomi"
}

variable "namespace_compartment_description" {
  description = "Parent namespace compartment description."
  type        = string
  default     = "Parent namespace compartment for workload infrastructure."
}

variable "workload_compartment_name" {
  description = "Child workload compartment name."
  type        = string
  default     = "litomi-prod"
}

variable "workload_compartment_description" {
  description = "Child workload compartment description."
  type        = string
  default     = "Production workload compartment."
}

variable "worker_tag_namespace_name" {
  description = "Tenancy-unique defined tag namespace used to identify OKE worker instances."
  type        = string
  default     = "LitomiIdentity"
}

variable "worker_tag_namespace_description" {
  description = "Description for the shared defined tag namespace used by OKE worker instances."
  type        = string
  default     = "Defined tags used to scope workload principals."
}

variable "worker_tag_key_name" {
  description = "Defined tag key used to identify OKE worker instances."
  type        = string
  default     = "principal_set"
}

variable "worker_tag_key_description" {
  description = "Description for the OKE worker instance defined tag key."
  type        = string
  default     = "Identifies workload principals that are allowed to read OCI Vault secrets."
}

variable "worker_tag_value" {
  description = "Optional override for the OKE worker instance principal tag value."
  type        = string
  default     = null
  nullable    = true
}

variable "availability_domain" {
  description = "Availability domain used by the worker node pools."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key injected into worker nodes."
  type        = string
}

variable "node_image_id" {
  description = "OKE worker image OCID."
  type        = string
}

variable "node_boot_volume_size_in_gbs" {
  description = "Boot volume size in GB for OKE worker nodes."
  type        = number
  default     = 100
}

variable "kubernetes_version" {
  description = "Target Kubernetes version for the OKE cluster."
  type        = string
  default     = "v1.35.2"
}

variable "vcn_cidr_blocks" {
  description = "VCN IPv4 CIDR blocks."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN."
  type        = string
  default     = "litomiprod"
}

variable "public_lb_subnet_cidr_block" {
  description = "Public LB subnet IPv4 CIDR block."
  type        = string
  default     = "10.10.0.0/24"
}

variable "worker_subnet_cidr_block" {
  description = "Worker subnet IPv4 CIDR block."
  type        = string
  default     = "10.10.1.0/24"
}

variable "api_endpoint_subnet_cidr_block" {
  description = "API endpoint subnet IPv4 CIDR block."
  type        = string
  default     = "10.10.2.0/28"
}

variable "bastion_subnet_cidr_block" {
  description = "OCI Bastion private endpoint subnet IPv4 CIDR block."
  type        = string
  default     = "10.10.2.16/28"
}

variable "pod_subnet_cidr_block" {
  description = "Pod subnet IPv4 CIDR block."
  type        = string
  default     = "10.10.16.0/20"
}

variable "bastion_client_allowed_cidrs_ipv4" {
  description = "Operator IPv4 CIDRs allowed to create OCI Bastion sessions for the private Kubernetes API endpoint."
  type        = list(string)

  validation {
    condition = (
      length(var.bastion_client_allowed_cidrs_ipv4) > 0 &&
      alltrue([for cidr in var.bastion_client_allowed_cidrs_ipv4 : can(cidrnetmask(cidr))])
    )
    error_message = "bastion_client_allowed_cidrs_ipv4 must contain at least one valid IPv4 CIDR block."
  }
}

variable "kubernetes_pods_cidr" {
  description = "Cluster pod CIDR."
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.kubernetes_pods_cidr))
    error_message = "kubernetes_pods_cidr must be a single IPv4 CIDR, for example 10.244.0.0/16."
  }
}

variable "kubernetes_services_cidr" {
  description = "Cluster service CIDR."
  type        = string
  default     = "10.96.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.kubernetes_services_cidr))
    error_message = "kubernetes_services_cidr must be a single IPv4 CIDR, for example 10.96.0.0/16."
  }
}

variable "node_pools" {
  description = "Node pool definitions keyed by node pool role."
  type = map(object({
    size          = number
    node_label    = string
    shape         = string
    ocpus         = number
    memory_in_gbs = number
    vault_access  = bool
  }))
  default = {
    platform = {
      size          = 1
      node_label    = "platform"
      shape         = "VM.Standard.A1.Flex"
      ocpus         = 2
      memory_in_gbs = 4
      vault_access  = true
    }
    workload = {
      size          = 1
      node_label    = "workload"
      shape         = "VM.Standard.A1.Flex"
      ocpus         = 2
      memory_in_gbs = 8
      vault_access  = false
    }
  }
}

variable "worker_external_https_cidrs_ipv4" {
  description = "Explicit IPv4 CIDR allowlist for worker node HTTPS egress via NAT."
  type        = list(string)

  validation {
    condition = (
      length(var.worker_external_https_cidrs_ipv4) > 0 &&
      alltrue([for cidr in var.worker_external_https_cidrs_ipv4 : can(cidrnetmask(cidr))])
    )
    error_message = "worker_external_https_cidrs_ipv4 must contain at least one valid IPv4 CIDR block."
  }
}

variable "pod_external_https_cidrs_ipv4" {
  description = "Explicit IPv4 CIDR allowlist for pod HTTPS egress via NAT."
  type        = list(string)

  validation {
    condition = (
      length(var.pod_external_https_cidrs_ipv4) > 0 &&
      alltrue([for cidr in var.pod_external_https_cidrs_ipv4 : can(cidrnetmask(cidr))])
    )
    error_message = "pod_external_https_cidrs_ipv4 must contain at least one valid IPv4 CIDR block."
  }
}

variable "pod_postgresql_cidrs_ipv4" {
  description = "IPv4 CIDRs allowed for pod PostgreSQL egress via NAT."
  type        = list(string)

  validation {
    condition = (
      length(var.pod_postgresql_cidrs_ipv4) > 0 &&
      alltrue([for cidr in var.pod_postgresql_cidrs_ipv4 : can(cidrnetmask(cidr))])
    )
    error_message = "pod_postgresql_cidrs_ipv4 must contain at least one valid IPv4 CIDR block."
  }
}

variable "pod_postgresql_ports" {
  description = "TCP ports allowed for pod PostgreSQL egress via NAT."
  type        = set(number)

  validation {
    condition = (
      length(var.pod_postgresql_ports) > 0 &&
      alltrue([for port in var.pod_postgresql_ports : port >= 1 && port <= 65535 && port == floor(port)])
    )
    error_message = "pod_postgresql_ports must contain at least one valid TCP port number."
  }
}

variable "pod_redis_cidrs_ipv4" {
  description = "IPv4 CIDRs allowed for pod Redis egress via NAT."
  type        = list(string)

  validation {
    condition = (
      length(var.pod_redis_cidrs_ipv4) > 0 &&
      alltrue([for cidr in var.pod_redis_cidrs_ipv4 : can(cidrnetmask(cidr))])
    )
    error_message = "pod_redis_cidrs_ipv4 must contain at least one valid IPv4 CIDR block."
  }
}

variable "pod_redis_ports" {
  description = "TCP ports allowed for pod Redis egress via NAT."
  type        = set(number)

  validation {
    condition = (
      length(var.pod_redis_ports) > 0 &&
      alltrue([for port in var.pod_redis_ports : port >= 1 && port <= 65535 && port == floor(port)])
    )
    error_message = "pod_redis_ports must contain at least one valid TCP port number."
  }
}
