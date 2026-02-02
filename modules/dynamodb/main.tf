# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - DynamoDB table not encrypted with KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Encryption with a customer-managed KMS key requires an organization-specific KMS key ARN which must be created and managed separately
# Fix: To enable encryption with a customer-managed KMS CMK:
#   1. Create or identify a KMS Customer Managed Key (CMK) for DynamoDB encryption:
#      resource "aws_kms_key" "dynamodb" {
#        description             = "KMS key for DynamoDB table encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#      }
#      resource "aws_kms_alias" "dynamodb" {
#        name          = "alias/dynamodb-${var.table_name}"
#        target_key_id = aws_kms_key.dynamodb.key_id
#      }
#   2. Add a server_side_encryption block to the DynamoDB table:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn
#      }
#   3. Ensure appropriate KMS key policies are in place to allow DynamoDB service access
#   4. Note: Without the kms_key_arn specified, setting enabled = true will use AWS managed key (alias/aws/dynamodb)
# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for DynamoDB table backup and restore capability
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
