# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - DynamoDB table not encrypted with customer-managed KMS key
# Resource: aws_dynamodb_table.main_table
# Reason: Requires a customer-managed KMS key ARN which must be created separately
#         or provided by the organization. This is a business decision that requires:
#         - Determining key management strategy (dedicated key vs shared key)
#         - Setting appropriate key policies and access controls
#         - Considering key rotation policies
#         - Understanding cost implications of customer-managed keys
# Fix: To remediate this finding:
#   1. Create a KMS key for DynamoDB encryption (or use existing key):
#      resource "aws_kms_key" "dynamodb" {
#        description             = "KMS key for DynamoDB table encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#      }
#   2. Add server_side_encryption block to the DynamoDB table:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn
#      }
#   3. Ensure appropriate IAM permissions for the KMS key to be used by DynamoDB
# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for backup and restore capabilities
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
