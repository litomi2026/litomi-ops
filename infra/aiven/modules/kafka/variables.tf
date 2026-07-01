variable "project" {
  description = "Aiven project that hosts the Kafka service."
  type        = string
}

variable "service_name" {
  description = "Aiven Kafka service name within the project."
  type        = string
}

variable "topics" {
  description = "Kafka topics to manage, keyed by topic name. retention_ms/cleanup_policy/min_insync_replicas are optional; omit them to inherit the service defaults (required on the Aiven free tier, which fixes retention)."
  type = map(object({
    partitions          = number
    replication         = number
    retention_ms        = optional(number)
    cleanup_policy      = optional(string)
    min_insync_replicas = optional(number)
  }))

  validation {
    condition     = alltrue([for t in values(var.topics) : t.partitions >= 1 && t.replication >= 1 && (t.min_insync_replicas == null || (t.min_insync_replicas >= 1 && t.min_insync_replicas <= t.replication))])
    error_message = "Each topic needs partitions >= 1, replication >= 1, and (if set) 1 <= min_insync_replicas <= replication."
  }
}

variable "users" {
  description = "Per-service Kafka SASL users to create (least-privilege principals)."
  type        = set(string)
  default     = []
}

variable "acls" {
  description = "Least-privilege ACL grants. permission is one of admin|read|readwrite|write."
  type = list(object({
    username   = string
    topic      = string
    permission = string
  }))
  default = []

  validation {
    condition     = alltrue([for a in var.acls : contains(["admin", "read", "readwrite", "write"], a.permission)])
    error_message = "ACL permission must be one of admin, read, readwrite, write."
  }
}
