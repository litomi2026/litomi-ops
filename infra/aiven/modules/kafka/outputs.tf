output "user_passwords" {
  description = "Generated SASL passwords for the created Kafka users, keyed by username. Load each into the matching app secret, then restart the app."
  sensitive   = true
  value       = { for username, user in aiven_kafka_user.this : username => user.password }
}

output "topic_names" {
  description = "Managed Kafka topic names."
  value       = keys(aiven_kafka_topic.this)
}
