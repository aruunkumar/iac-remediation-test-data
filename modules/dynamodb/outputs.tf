output "table_name" {
  description = "The name of the main DynamoDB table"
  value       = aws_dynamodb_table.main_table.name
}

output "table_arn" {
  description = "The ARN of the main DynamoDB table"
  value       = aws_dynamodb_table.main_table.arn
}

output "chat_history_table_name" {
  description = "The name of the chat history DynamoDB table"
  value       = aws_dynamodb_table.chat_history_table.name
}

output "chat_history_table_arn" {
  description = "The ARN of the chat history DynamoDB table"
  value       = aws_dynamodb_table.chat_history_table.arn
}