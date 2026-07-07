variable "discord_webhook_url" {
  description = "Discord webhook URL that Grafana alerting posts to."
  type        = string
  nullable    = false
  sensitive   = true
}
