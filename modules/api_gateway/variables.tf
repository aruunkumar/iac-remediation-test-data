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

variable "log_retention_days" {
  description = "Number of days to retain API Gateway access logs"
  type        = number
  default     = 7
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for API Gateway"
  type        = bool
  default     = true
}

variable "enable_metrics" {
  description = "Enable CloudWatch metrics for API Gateway"
  type        = bool
  default     = true
}

variable "logging_level" {
  description = "Logging level for API Gateway (OFF, ERROR, INFO)"
  type        = string
  default     = "ERROR"
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.logging_level)
    error_message = "Logging level must be one of: OFF, ERROR, INFO."
  }
}
