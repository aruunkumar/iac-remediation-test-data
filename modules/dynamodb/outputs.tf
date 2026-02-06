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

# AGENT-FIXED: CKV_AWS_119 - Added KMS key outputs for reference and IAM policy configuration
output "kms_key_id" {
  description = "The ID of the KMS key used for DynamoDB table encryption"
  value       = aws_kms_key.dynamodb_key.key_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for DynamoDB table encryption"
  value       = aws_kms_key.dynamodb_key.arn
}
