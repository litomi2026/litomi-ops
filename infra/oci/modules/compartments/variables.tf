variable "tenancy_ocid" {
  description = "OCI tenancy OCID. The parent namespace compartment is created directly under this root."
  type        = string
}

variable "namespace_name" {
  description = "Parent namespace compartment name."
  type        = string
}

variable "namespace_description" {
  description = "Parent namespace compartment description."
  type        = string
}

variable "workload_name" {
  description = "Environment compartment name."
  type        = string
}

variable "workload_description" {
  description = "Environment compartment description."
  type        = string
}

variable "freeform_tags" {
  description = "Freeform tags applied to the compartments."
  type        = map(string)
  default     = {}
}
