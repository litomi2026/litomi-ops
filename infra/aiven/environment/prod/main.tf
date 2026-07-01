provider "aiven" {
  api_token = var.aiven_api_token
}

locals {
  # Topic names are the external contract defined in litomi: packages/events/src/topics.ts.
  # Keep these strings in sync with that file (TOPIC_CHAT_MESSAGE / TOPIC_CHAT_PUSH_FANOUT).
  # The Aiven free tier fixes retention/cleanup/min.insync, so only partitions + replication
  # are set here; the rest inherit the Kafka service defaults. Add the config fields back on
  # a paid plan (the module supports them as optional).
  topics = {
    "chat.message" = {
      partitions  = var.chat_message_partitions
      replication = var.kafka_replication
    }
    "chat.push.fanout" = {
      partitions  = var.chat_push_fanout_partitions
      replication = var.kafka_replication
    }
  }

  service_users = var.manage_service_users ? toset([
    var.kafka_user_api,
    var.kafka_user_chat_worker,
    var.kafka_user_chat_push,
  ]) : toset([])

  # Least-privilege grants derived from the code's producer/consumer roles:
  #   litomi-api       -> produces chat.message
  #   chat-worker      -> consumes chat.message, produces chat.push.fanout
  #   chat-push        -> consumes AND re-enqueues chat.push.fanout (keyset pagination) => readwrite
  service_acls = var.manage_service_users ? [
    { username = var.kafka_user_api, topic = "chat.message", permission = "write" },
    { username = var.kafka_user_chat_worker, topic = "chat.message", permission = "read" },
    { username = var.kafka_user_chat_worker, topic = "chat.push.fanout", permission = "write" },
    { username = var.kafka_user_chat_push, topic = "chat.push.fanout", permission = "readwrite" },
  ] : []
}

module "kafka" {
  source = "../../modules/kafka"

  project      = var.aiven_project
  service_name = var.kafka_service_name
  topics       = local.topics
  users        = local.service_users
  acls         = local.service_acls
}
