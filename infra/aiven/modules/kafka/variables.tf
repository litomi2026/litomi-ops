variable "project" {
  description = "Aiven project that hosts the Kafka service."
  type        = string
}

variable "service_name" {
  description = "Aiven Kafka service name within the project."
  type        = string
}

variable "topics" {
  description = "Kafka topics to manage, keyed by topic name."
  type = map(object({
    partitions          = number
    replication         = number
    retention_ms        = number
    cleanup_policy      = string
    min_insync_replicas = number
  }))

  validation {
    condition     = alltrue([for t in values(var.topics) : t.partitions >= 1 && t.replication >= 1 && t.min_insync_replicas >= 1 && t.min_insync_replicas <= t.replication])
    error_message = "Each topic needs partitions >= 1, replication >= 1, and 1 <= min_insync_replicas <= replication."
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
