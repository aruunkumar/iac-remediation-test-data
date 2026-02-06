# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - Encrypt DynamoDB table using KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Requires creating or referencing a customer-managed KMS key which is organization-specific
# Fix: To enable encryption with a customer-managed KMS key:
#   1. Create a KMS key (or reference an existing one):
#     resource "aws_kms_key" "dynamodb_key" {
#       description             = "KMS key for DynamoDB table encryption"
#       deletion_window_in_days = 10
#       enable_key_rotation     = true
#     }
#   2. Add server_side_encryption block to the DynamoDB table:
#     server_side_encryption {
#       enabled     = true
#       kms_key_arn = aws_kms_key.dynamodb_key.arn
#     }
#   3. Optionally create a KMS key alias:
#     resource "aws_kms_alias" "dynamodb_key_alias" {
#       name          = "alias/${var.table_name}-key"
#       target_key_id = aws_kms_key.dynamodb_key.key_id
#     }

# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for DynamoDB table
resource "aws_dynamodb_table" "main_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "alias"
  range_key    = "trainingId"

  attribute {
    name = "alias"
    type = "S"
  }

  attribute {
    name = "trainingId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# resource "aws_dynamodb_table" "chat_history_table" {
#   name         = var.conversation_history_table_name
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "conversation_id"
#   range_key    = "user_id"
  
#   ttl {
#     attribute_name = "conversation_age"
#     enabled        = true
#   }

#   attribute {
#     name = "conversation_id"
#     type = "S"
#   }

#   attribute {
#     name = "user_id"
#     type = "N"
#   }
# }