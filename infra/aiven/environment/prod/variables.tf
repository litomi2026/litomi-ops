variable "aiven_api_token" {
  description = "Aiven API token with access to the project. Set as a sensitive HCP Terraform workspace variable."
  type        = string
  sensitive   = true
}

variable "aiven_project" {
  description = "Aiven project that hosts the Kafka service (e.g. litomi2026, inferred from kafka-litomi2026.h.aivencloud.com — verify in the Aiven console)."
  type        = string
}

variable "kafka_service_name" {
  description = "Aiven Kafka service name within the project (e.g. kafka — verify in the Aiven console)."
  type        = string
}

variable "kafka_replication" {
  description = "Replication factor for chat topics. Match the Aiven Kafka plan's broker count (Aiven standard is 3)."
  type        = number
  default     = 3
}

variable "kafka_min_insync_replicas" {
  description = "min.insync.replicas for chat topics. Must be <= kafka_replication; 2 with RF 3 keeps producing safe while one broker is down."
  type        = number
  default     = 2
}

variable "chat_message_partitions" {
  description = "Partitions for chat.message (key = streamId). Cannot be decreased later; increasing rehashes keys and breaks per-stream ordering."
  type        = number
  default     = 6
}

variable "chat_push_fanout_partitions" {
  description = "Partitions for chat.push.fanout (key = artistId). Cannot be decreased later; increasing rehashes keys and breaks per-artist ordering."
  type        = number
  default     = 6
}

variable "chat_message_retention_ms" {
  description = "Retention for chat.message. Messages are also persisted to CockroachDB, so Kafka is a transport/replay buffer (default 1 day)."
  type        = number
  default     = 86400000
}

variable "chat_push_fanout_retention_ms" {
  description = "Retention for chat.push.fanout fan-out jobs (default 1 day)."
  type        = number
  default     = 86400000
}

variable "manage_service_users" {
  description = "Create per-service Kafka users + least-privilege ACLs. Non-breaking (avnadmin keeps working); apps switch to these users via the credential migration in README before the default wildcard ACL is removed."
  type        = bool
  default     = true
}

# Per-service principal names. Parameterized so they can be renamed without code edits.
variable "kafka_user_api" {
  description = "Aiven Kafka username for litomi-api (producer of chat.message)."
  type        = string
  default     = "litomi-api"
}

variable "kafka_user_chat_worker" {
  description = "Aiven Kafka username for chat-worker (consumes chat.message, produces chat.push.fanout)."
  type        = string
  default     = "litomi-chat-worker"
}

variable "kafka_user_chat_push" {
  description = "Aiven Kafka username for chat-push (consumes and re-enqueues chat.push.fanout)."
  type        = string
  default     = "litomi-chat-push"
}
