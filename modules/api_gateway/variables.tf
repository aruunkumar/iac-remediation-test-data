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

# AGENT-FIXED: CKV_AWS_120 - Added variables for API Gateway cache cluster configuration
variable "enable_cache_cluster" {
  description = "Enable cache cluster for the API Gateway stage to improve performance and reduce backend load"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Size of the cache cluster for the stage, if enabled. Allowed values: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237"
  type        = string
  default     = "0.5"
}
