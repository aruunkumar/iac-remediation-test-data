variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "query_log_retention_days" {
  description = "Number of days to retain Route53 query logs in CloudWatch"
  type        = number
  default     = 7
}
