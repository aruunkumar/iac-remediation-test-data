# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - DynamoDB table should use KMS Customer Managed CMK for encryption
# Resource: aws_dynamodb_table.main_table
# Reason: Using a Customer Managed CMK requires creating or referencing an existing KMS key, which is an organizational decision that involves key management, rotation policies, access controls, and cost considerations
# Fix: To remediate this finding:
#   1. Create a KMS key (or reference an existing one) for DynamoDB encryption:
#      resource "aws_kms_key" "dynamodb" {
#        description             = "KMS key for DynamoDB table encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#        tags = {
#          Name = "dynamodb-${var.table_name}-key"
#        }
#      }
#      resource "aws_kms_alias" "dynamodb" {
#        name          = "alias/dynamodb-${var.table_name}"
#        target_key_id = aws_kms_key.dynamodb.key_id
#      }
#   2. Add server_side_encryption block to this table with the KMS key ARN:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn
#      }
#   3. Update IAM policies to grant necessary permissions for DynamoDB to use the KMS key:
#      - kms:Decrypt
#      - kms:Encrypt
#      - kms:GenerateDataKey
#      - kms:DescribeKey
#   4. Consider the additional costs for KMS key usage and API calls

# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for DynamoDB table to enable continuous backups
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
