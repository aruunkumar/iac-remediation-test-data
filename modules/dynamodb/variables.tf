variable "table_name" {
  description = "The name of the main DynamoDB table"
  type        = string
}

variable "conversation_history_table_name" {
  description = "The name of the conversation history DynamoDB table"
  type        = string
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB tables"
  type        = bool
  default     = true
}
