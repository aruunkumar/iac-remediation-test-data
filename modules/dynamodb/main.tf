# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - DynamoDB table should be encrypted using KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Requires creating or referencing a KMS Customer Managed Key (CMK), which involves organizational key management decisions
# Fix: Configure server-side encryption with a Customer Managed CMK:
#   1. Create a KMS key (or reference an existing one):
#      resource "aws_kms_key" "dynamodb" {
#        description             = "KMS key for DynamoDB table encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#      }
#      resource "aws_kms_alias" "dynamodb" {
#        name          = "alias/dynamodb-${var.table_name}"
#        target_key_id = aws_kms_key.dynamodb.key_id
#      }
#   2. Add server_side_encryption block to the table:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn
#      }
#   3. Ensure appropriate KMS key policies are configured for DynamoDB service access
#   4. Consider using a centralized KMS key if organization policy requires it
#
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
#   
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
