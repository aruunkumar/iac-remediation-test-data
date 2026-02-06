variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "query_log_retention_days" {
  description = "Number of days to retain Route 53 query logs in CloudWatch"
  type        = number
  default     = 7
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "production"
}

variable "cloudwatch_kms_key_arn" {
  description = "ARN of the KMS key to use for CloudWatch Logs encryption"
  type        = string
  default     = null
}
