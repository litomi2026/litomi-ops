variable "discord_critical_webhook_url" {
  description = "Discord webhook URL for critical alerts (and the default catch-all)."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "discord_warning_webhook_url" {
  description = "Discord webhook URL for warning alerts (severity=warning)."
  type        = string
  nullable    = false
  sensitive   = true
}
