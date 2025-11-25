# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - Ensure DynamoDB Tables are encrypted using a KMS Customer Managed CMK
# Resource: module.dynamodb.aws_dynamodb_table.main_table
# Reason: Requires KMS key resource creation and business decisions on key management strategy (rotation, deletion window, permissions)
# Fix: 1. Create or reference a KMS key:
#      resource "aws_kms_key" "dynamodb" {
#        description             = "KMS key for DynamoDB table encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#      }
#      resource "aws_kms_alias" "dynamodb" {
#        name          = "alias/${var.table_name}-key"
#        target_key_id = aws_kms_key.dynamodb.key_id
#      }
#      2. Add server_side_encryption block to the table below:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn
#      }
#      Note: Ensure IAM permissions allow DynamoDB service to use the KMS key

# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for continuous backups (35-day retention)
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
