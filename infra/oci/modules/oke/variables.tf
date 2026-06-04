variable "compartment_id" {
  description = "Target OCI compartment OCID."
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for named OKE resources."
  type        = string
}

variable "kubernetes_version" {
  description = "OKE Kubernetes version."
  type        = string
}

variable "vcn_id" {
  description = "VCN OCID for the cluster."
  type        = string
}

variable "api_endpoint_subnet_id" {
  description = "API endpoint subnet OCID."
  type        = string
}

variable "api_endpoint_nsg_ids" {
  description = "NSG OCIDs attached to the Kubernetes API endpoint."
  type        = list(string)
  default     = []
}

variable "service_lb_subnet_ids" {
  description = "Subnets used by Kubernetes-created load balancers."
  type        = list(string)
}

variable "worker_subnet_id" {
  description = "Subnet used by worker nodes."
  type        = string
}

variable "worker_nsg_ids" {
  description = "Additional NSG OCIDs attached to worker nodes."
  type        = list(string)
  default     = []
}

variable "pod_subnet_id" {
  description = "Subnet used by pods."
  type        = string
}

variable "pod_nsg_ids" {
  description = "NSG OCIDs attached to VCN-native pods."
  type        = list(string)
  default     = []
}

variable "worker_tag_namespace_name" {
  description = "Defined tag namespace name applied to OKE worker instances."
  type        = string
}

variable "worker_tag_key_name" {
  description = "Defined tag key name applied to OKE worker instances."
  type        = string
}

variable "worker_tag_value" {
  description = "Defined tag value applied to OKE worker instances."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain used for node pool placement."
  type        = string
}

variable "node_image_id" {
  description = "OKE worker image OCID."
  type        = string
}

variable "node_boot_volume_size_in_gbs" {
  description = "Boot volume size in GB for OKE worker nodes."
  type        = number
}

variable "ssh_public_key" {
  description = "SSH public key injected into worker nodes."
  type        = string
}

variable "node_pools" {
  description = "Node pool definitions keyed by logical pool role."
  type = map(object({
    size          = number
    node_label    = string
    shape         = string
    ocpus         = number
    memory_in_gbs = number
    vault_access  = bool
  }))
}

variable "kubernetes_pods_cidr" {
  description = "Cluster pod CIDR."
  type        = string
}

variable "kubernetes_services_cidr" {
  description = "Cluster service CIDR."
  type        = string
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node."
  type        = number
  default     = 31
}

variable "freeform_tags" {
  description = "Freeform tags applied to OKE resources."
  type        = map(string)
  default     = {}
}
