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

# Added variables for API Gateway security compliance
variable "enable_api_gateway_cache" {
  description = "Enable caching for API Gateway stage"
  type        = bool
  default     = false
}

variable "api_gateway_cache_size" {
  description = "Size of the cache cluster for the API Gateway stage (in GB). Valid values: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237"
  type        = string
  default     = "0.5"
}

variable "api_gateway_logging_level" {
  description = "Logging level for API Gateway stage. Valid values: OFF, ERROR, INFO"
  type        = string
  default     = "ERROR"
}
