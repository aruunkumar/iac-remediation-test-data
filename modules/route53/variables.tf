variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

# AGENT-FIXED: CKV2_AWS_39 - Added variable for Route53 query log retention period
variable "query_log_retention_days" {
  description = "Number of days to retain Route53 query logs in CloudWatch"
  type        = number
  default     = 30
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.query_log_retention_days)
    error_message = "The query_log_retention_days must be one of: 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, or 3653."
  }
}
