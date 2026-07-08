variable "region" {
  description = "OCI region that holds the Vault."
  type        = string
  nullable    = false
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID for provider authentication."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "user_ocid" {
  description = "OCI user OCID for provider authentication."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "fingerprint" {
  description = "OCI API key fingerprint for provider authentication."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "private_key" {
  description = "OCI API private key (PEM) for provider authentication."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "private_key_password" {
  description = "Passphrase for the OCI API private key, if any."
  type        = string
  default     = null
  sensitive   = true
}

variable "compartment_id" {
  description = "OCI workload compartment OCID that holds the Vault. Copied from the oci-prod `workload_compartment_id` output."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "vault_ocid" {
  description = "OCI KMS Vault OCID. Copied from the oci-prod `vault_ocid` output."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "kms_key_ocid" {
  description = "OCI KMS key OCID used to encrypt the secret. Copied from the oci-prod `kms_key_ocid` output."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "grafana_collector_secret_name" {
  description = "OCI Vault secret name consumed by the grafana-k8s-monitoring ExternalSecret."
  type        = string
  default     = "litomi-prod-grafana-cloud-k8s"
  nullable    = false
}

variable "grafana_collector_secret_ocid" {
  description = "OCID of the existing collector Vault secret, adopted via import. Read from the oci-prod state before releasing the module resource."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "freeform_tags" {
  description = "Freeform tags applied to the OCI Vault secret."
  type        = map(string)
  default     = {}
}
