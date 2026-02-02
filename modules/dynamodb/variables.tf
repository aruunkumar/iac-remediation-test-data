variable "table_name" {
  description = "The name of the main DynamoDB table"
  type        = string
}

variable "conversation_history_table_name" {
  description = "The name of the conversation history DynamoDB table"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for DynamoDB table encryption. If not provided, uses AWS managed key."
  type        = string
  default     = null
}
