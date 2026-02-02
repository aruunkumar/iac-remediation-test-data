# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - DynamoDB table requires encryption with KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Requires creating a KMS Customer Managed Key (CMK) with organization-specific key policies, rotation settings, and access controls
# Fix: To enable KMS Customer Managed CMK encryption:
#   1. Create an aws_kms_key resource with appropriate key policy:
#      resource "aws_kms_key" "dynamodb_key" {
#        description             = "KMS key for DynamoDB table encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#      }
#   2. Create a KMS key alias for easier reference:
#      resource "aws_kms_alias" "dynamodb_key_alias" {
#        name          = "alias/dynamodb-${var.table_name}"
#        target_key_id = aws_kms_key.dynamodb_key.key_id
#      }
#   3. Add server_side_encryption block to the DynamoDB table:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb_key.arn
#      }
#   4. Ensure IAM roles that access the table have kms:Decrypt and kms:DescribeKey permissions
# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for DynamoDB table backup
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
