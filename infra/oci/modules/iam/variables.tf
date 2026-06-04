variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "policy_compartment_id" {
  description = "Compartment OCID that stores IAM policies."
  type        = string
}

variable "workload_compartment_id" {
  description = "Compartment OCID that contains workload resources."
  type        = string
}

variable "tag_namespace_compartment_id" {
  description = "Compartment OCID that owns the defined tag namespace used by OKE worker nodes."
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for named IAM resources."
  type        = string
}

variable "cluster_id" {
  description = "OKE cluster OCID used in conditional policies."
  type        = string
}

variable "worker_tag_namespace_name" {
  description = "Defined tag namespace name used to identify OKE worker instances."
  type        = string
}

variable "worker_tag_key_name" {
  description = "Defined tag key name used to identify OKE worker instances."
  type        = string
}

variable "worker_tag_value" {
  description = "Defined tag value used to identify OKE worker instances."
  type        = string
}
