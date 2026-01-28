variable "rackspace_spot_token" {
  description = "Rackspace Spot authentication token"
  type        = string
  sensitive   = true
}

variable "monthly_budget_usd" {
  description = "Monthly budget in USD for spot instances"
  type        = number
  default     = 50

  validation {
    condition     = var.monthly_budget_usd >= 25
    error_message = "Budget must be at least $25/month to run 3 nodes at the minimum bid price ($0.01/hr × 730 hrs × 3 nodes = $21.90)."
  }
}
