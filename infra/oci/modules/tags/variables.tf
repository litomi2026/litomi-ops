variable "compartment_id" {
  description = "Compartment OCID that owns the defined tag namespace."
  type        = string
}

variable "namespace_name" {
  description = "Tenancy-unique defined tag namespace name."
  type        = string
}

variable "namespace_description" {
  description = "Description for the defined tag namespace."
  type        = string
}

variable "worker_tag_key_name" {
  description = "Defined tag key name used to scope OKE worker instance principals."
  type        = string
}

variable "worker_tag_key_description" {
  description = "Description for the OKE worker instance defined tag key."
  type        = string
}

variable "freeform_tags" {
  description = "Freeform tags applied to the tag namespace."
  type        = map(string)
  default     = {}
}
