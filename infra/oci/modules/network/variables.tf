variable "compartment_id" {
  description = "Target OCI compartment OCID."
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for named network resources."
  type        = string
}

variable "vcn_cidr_blocks" {
  description = "IPv4 CIDR blocks assigned to the VCN."
  type        = list(string)

  validation {
    condition = (
      length(var.vcn_cidr_blocks) > 0 &&
      alltrue([for cidr in var.vcn_cidr_blocks : can(cidrnetmask(cidr))])
    )
    error_message = "vcn_cidr_blocks must contain at least one valid IPv4 CIDR block."
  }
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{0,14}$", var.vcn_dns_label))
    error_message = "vcn_dns_label must start with a letter, contain only letters and numbers, and be 1-15 characters long."
  }
}

variable "public_lb_subnet_cidr_block" {
  description = "IPv4 CIDR block for the public load balancer subnet."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.public_lb_subnet_cidr_block))
    error_message = "public_lb_subnet_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "worker_subnet_cidr_block" {
  description = "IPv4 CIDR block for the worker subnet."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.worker_subnet_cidr_block))
    error_message = "worker_subnet_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "api_endpoint_subnet_cidr_block" {
  description = "IPv4 CIDR block for the API endpoint subnet."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.api_endpoint_subnet_cidr_block))
    error_message = "api_endpoint_subnet_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "bastion_subnet_cidr_block" {
  description = "IPv4 CIDR block for the OCI Bastion private endpoint subnet."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.bastion_subnet_cidr_block))
    error_message = "bastion_subnet_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "pod_subnet_cidr_block" {
  description = "IPv4 CIDR block for the pod subnet."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.pod_subnet_cidr_block))
    error_message = "pod_subnet_cidr_block must be a valid IPv4 CIDR block."
  }
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
  description = "Explicit IPv4 CIDR allowlist for pod PostgreSQL egress via NAT."
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
  description = "Explicit IPv4 CIDR allowlist for pod Redis egress via NAT."
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

variable "freeform_tags" {
  description = "Freeform tags applied to network resources."
  type        = map(string)
  default     = {}
}
