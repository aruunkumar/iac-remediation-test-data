variable "table_name" {
  description = "The name of the main DynamoDB table"
  type        = string
}

variable "conversation_history_table_name" {
  description = "The name of the conversation history DynamoDB table"
  type        = string
}

variable "region" {
  description = "The AWS region where DynamoDB tables are deployed"
  type        = string
}
