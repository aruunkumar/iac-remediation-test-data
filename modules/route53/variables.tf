variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

# AGENT-FIXED: CKV2_AWS_39 - Added variable for query log retention
variable "query_log_retention_days" {
  description = "The number of days to retain Route53 query logs in CloudWatch"
  type        = number
  default     = 30
}
