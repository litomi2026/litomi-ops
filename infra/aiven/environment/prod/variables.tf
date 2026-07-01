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
  description = "Replication factor for chat topics. Aiven enforces RF >= 2 and RF must not exceed the broker count; this 2-broker plan therefore requires exactly 2. Raise to 3 on a >=3-broker plan."
  type        = number
  default     = 2
}

variable "chat_message_partitions" {
  description = "Partitions for chat.message (key = streamId). Capped at 2 by the current Aiven Kafka plan (max 2 partitions per topic). Cannot be decreased later; increasing rehashes keys and breaks per-stream ordering."
  type        = number
  default     = 2
}

variable "chat_push_fanout_partitions" {
  description = "Partitions for chat.push.fanout (key = artistId). Capped at 2 by the current Aiven Kafka plan (max 2 partitions per topic). Cannot be decreased later; increasing rehashes keys and breaks per-artist ordering."
  type        = number
  default     = 2
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
