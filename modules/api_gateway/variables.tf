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

# AGENT-FIXED: CKV_AWS_76 - Added variable for CloudWatch log retention
variable "log_retention_days" {
  description = "The number of days to retain API Gateway logs in CloudWatch"
  type        = number
  default     = 7
}

# AGENT-FIXED: CKV2_AWS_29 - Added variable for WAF rate limiting
variable "waf_rate_limit" {
  description = "The maximum number of requests from a single IP address allowed in a 5-minute period"
  type        = number
  default     = 2000
}
