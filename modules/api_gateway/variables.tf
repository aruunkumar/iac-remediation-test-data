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

# Variables added for security remediation
variable "log_retention_days" {
  description = "The number of days to retain API Gateway logs in CloudWatch"
  type        = number
  default     = 7
}

variable "enable_cache" {
  description = "Whether to enable caching for the API Gateway stage"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "The size of the cache cluster for the stage, if enabled"
  type        = string
  default     = "0.5"
}

variable "api_gateway_logging_level" {
  description = "The logging level for API Gateway. Valid values are OFF, ERROR, and INFO"
  type        = string
  default     = "ERROR"
  
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.api_gateway_logging_level)
    error_message = "The logging level must be OFF, ERROR, or INFO."
  }
}
