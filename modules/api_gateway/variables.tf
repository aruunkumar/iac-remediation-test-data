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
  description = "Number of days to retain API Gateway logs in CloudWatch"
  type        = number
  default     = 7
}

variable "cloudwatch_kms_key_arn" {
  description = "ARN of the KMS key to use for CloudWatch Logs encryption"
  type        = string
  default     = null
}

variable "enable_cache_cluster" {
  description = "Whether to enable cache cluster for API Gateway stage"
  type        = bool
  default     = true
}

variable "cache_cluster_size" {
  description = "Size of the cache cluster for the API Gateway stage"
  type        = string
  default     = "0.5"
  validation {
    condition     = contains(["0.5", "1.6", "6.1", "13.5", "28.4", "58.2", "118", "237"], var.cache_cluster_size)
    error_message = "Cache cluster size must be one of: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237"
  }
}

variable "api_gateway_logging_level" {
  description = "Logging level for API Gateway stage (OFF, ERROR, or INFO)"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.api_gateway_logging_level)
    error_message = "API Gateway logging level must be one of: OFF, ERROR, INFO"
  }
}

variable "enable_data_trace" {
  description = "Whether to enable data trace logging for API Gateway"
  type        = bool
  default     = false
}

variable "enable_method_caching" {
  description = "Whether to enable caching for API Gateway method settings"
  type        = bool
  default     = true
}
