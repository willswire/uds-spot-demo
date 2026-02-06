variable "rackspace_spot_token" {
  description = "Rackspace Spot authentication token"
  type        = string
  sensitive   = true
}

variable "daily_budget_usd" {
  description = "Daily budget in USD for spot instances"
  type        = number
  default     = 10
}
