output "kafka_topics" {
  description = "Managed Kafka topic names."
  value       = module.kafka.topic_names
}

output "kafka_user_passwords" {
  description = "SASL passwords for the per-service Kafka users, keyed by username. Read with `terraform output -json kafka_user_passwords`, load each into the matching OCI Vault secret (KAFKA_USERNAME/KAFKA_PASSWORD), then restart the app. See README."
  sensitive   = true
  value       = module.kafka.user_passwords
}
