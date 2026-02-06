variable "api_name" {
  description = "The name of the API"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "The ARN of the Cognito user pool"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "The ID of the Cognito user pool"
  type        = string
}

variable "table_name" {
  description = "The name of the main DynamoDB table"
  type        = string
}

variable "chat_history_table_name" {
  description = "The name of the chat history DynamoDB table"
  type        = string
}

variable "lambda_source_dir" {
  description = "The directory containing the Lambda source code"
  type        = string
}

# Variables added for security compliance

variable "log_retention_days" {
  description = "Number of days to retain API Gateway access logs in CloudWatch (minimum 365 for compliance)"
  type        = number
  default     = 365
}

variable "cloudwatch_kms_key_id" {
  description = "ARN of the KMS key to use for encrypting CloudWatch logs"
  type        = string
  default     = null
}

variable "enable_cache" {
  description = "Enable cache cluster for API Gateway stage"
  type        = bool
  default     = true
}

variable "cache_cluster_size" {
  description = "Size of the cache cluster for API Gateway stage (0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237)"
  type        = string
  default     = "0.5"
}

variable "cache_ttl_seconds" {
  description = "Time to live (TTL) in seconds for cached responses"
  type        = number
  default     = 300
}

variable "logging_level" {
  description = "Logging level for API Gateway methods (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

variable "data_trace_enabled" {
  description = "Enable data trace logging for API Gateway methods"
  type        = bool
  default     = false
}
