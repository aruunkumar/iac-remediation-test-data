# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - Enable DynamoDB encryption using KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Requires a KMS Customer Managed Key (CMK) ARN which must be created or provided by the user
# Fix: To enable KMS CMK encryption:
#   1. Create or identify a KMS Customer Managed Key:
#      resource "aws_kms_key" "dynamodb" {
#        description             = "KMS key for DynamoDB table encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#      }
#      resource "aws_kms_alias" "dynamodb" {
#        name          = "alias/${var.table_name}-dynamodb"
#        target_key_id = aws_kms_key.dynamodb.key_id
#      }
#   2. Add the server_side_encryption block to the DynamoDB table:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn
#      }
#   3. Ensure the IAM role/user has necessary KMS permissions (kms:Decrypt, kms:DescribeKey)
#
# AGENT-FIXED: CKV_AWS_28 - Enabled DynamoDB point-in-time recovery for backup
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

  # Enable point-in-time recovery for backup and restore capabilities
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
