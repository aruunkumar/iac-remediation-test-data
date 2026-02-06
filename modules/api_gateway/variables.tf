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

# AGENT-FIXED: CKV_AWS_76 - Added variable for CloudWatch log retention days
variable "log_retention_days" {
  description = "Number of days to retain API Gateway access logs in CloudWatch"
  type        = number
  default     = 30
}

# AGENT-FIXED: CKV2_AWS_4 - Added variable for API Gateway logging level
variable "api_logging_level" {
  description = "Logging level for API Gateway methods (OFF, ERROR, INFO)"
  type        = string
  default     = "ERROR"
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.api_logging_level)
    error_message = "The api_logging_level must be one of: OFF, ERROR, INFO."
  }
}
